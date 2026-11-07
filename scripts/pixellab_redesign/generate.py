"""PixelLab 정적 에셋 제작. 접수한 작업은 ID로 재개하며 POST를 자동 재시도하지 않는다."""
import argparse
import base64
import concurrent.futures
import datetime
import hashlib
import io
import json
import re
import sys
import threading
import time
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
import pixellab_transport as api
LOCK = threading.Lock()


def write(path, value):
    temporary=path.with_suffix(path.suffix+'.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n')
    temporary.replace(path)


def charged(response):
    last = response.get('last_response') or {}
    usage = response.get('usage') or last.get('billing_usage') or last.get('usage') or {}
    return float(usage['generations']) if usage.get('generations') is not None else None


def committed_cost(raw):
    total = 0.0
    for folder in raw.iterdir():
        if not folder.is_dir():
            continue
        result = folder/'response.json'
        intent = folder/'intent.json'
        if result.exists():
            response = json.loads(result.read_text())
            cost = charged(response)
            if cost is None and response.get('status') == 'completed':
                raise RuntimeError('Completed job has no billing data: '+folder.name)
            total += cost if cost is not None else (float(json.loads(intent.read_text())['reservation']) if intent.exists() else 0)
        elif intent.exists():
            total += float(json.loads(intent.read_text())['reservation'])
    return total


def reference(path, role):
    image = Image.open(path).convert('RGBA')
    return {'image':api.b64(image), 'size':{'width':image.width,'height':image.height}, 'usage_description':role}


def body(spec, raw):
    if spec['kind']=='animation':
        image=Image.open(raw/spec['source']).convert('RGBA')
        payload={'first_frame':api.b64(image),'action':spec['action'],'frame_count':8,
                 'no_background':True,'seed':spec['seed']}
        if spec.get('returnToStart',False):payload['last_frame']=api.b64(image)
        return payload
    w,h = spec['size']
    payload = {'description':spec['description'], 'image_size':{'width':w,'height':h},
               'no_background':spec['kind']!='background',
               'seed':int(hashlib.sha256(spec['id'].encode()).hexdigest()[:8],16) % (2**31),
               'target_palette':{'max_colors':64},
               'style_image':reference(raw/spec['style'],'Pixel cluster scale, material shading and colored line craft only; do not copy the human subject.'),
               'style_options':{'color_palette':False,'outline':True,'detail':True,'shading':True}}
    if spec.get('subject'):
        payload['reference_images']=[reference(raw/spec['subject'],'Preserve this exact adult woman, face, hairstyle, pose, scale and canvas placement. Change only the outfit as described.')]
    return payload


def save_images(response, folder):
    last = response.get('last_response') or {}
    images = last.get('images') or ([last['image']] if last.get('image') else [])
    if not images:
        raise RuntimeError('Completed job has no images: '+folder.name)
    metadata = []
    for i, item in enumerate(images):
        encoded=item['base64'].split(',',1)[-1]
        image=Image.open(io.BytesIO(base64.b64decode(encoded))).convert('RGBA')
        path=folder/f'variant-{i:02d}.png'
        image.save(path)
        metadata.append({'path':path.name,'size':list(image.size),'bbox':image.getbbox(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    write(folder/'receipt.json',{'jobId':response.get('id') or response.get('background_job_id'),
                              'actualGenerations':charged(response),'images':metadata,
                              'completedAt':datetime.datetime.now(datetime.timezone.utc).isoformat()})


def generate(spec, manifest, raw, token):
    folder=raw/spec['id'];folder.mkdir(parents=True,exist_ok=True)
    result_path=folder/'response.json';submission_path=folder/'submission.json';intent=folder/'intent.json'
    if result_path.exists():
        response=json.loads(result_path.read_text())
        if response.get('status')=='completed':
            if not (folder/'receipt.json').exists():save_images(response,folder)
            return
        raise RuntimeError('Recorded job failed; manual quality triage required: '+spec['id'])
    if submission_path.exists():
        submitted=json.loads(submission_path.read_text())
    else:
        with LOCK:
            if intent.exists():
                raise RuntimeError('Submission outcome unknown; refusing a duplicate POST: '+spec['id'])
            estimate=float(spec['estimatedGenerations'])
            if committed_cost(raw)+estimate > manifest['maxGenerations']:
                raise RuntimeError('Generation ceiling reached')
            write(intent,{'reservation':estimate,'startedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'spec':spec})
        # The intent remains reserved if the response is lost; a rerun never silently resubmits.
        submitted=api.request(spec.get('endpoint','/generate-image-v2'),token,body(spec,raw))
        write(submission_path,submitted)
        with LOCK:print('submitted',spec['id'],submitted['background_job_id'],flush=True)
    job_id=submitted['background_job_id']
    started=time.monotonic()
    while time.monotonic()-started < 1200:
        response=api.request('/background-jobs/'+job_id,token)
        if response.get('status') in ['completed','failed']:
            write(result_path,response)
            if response['status']!='completed':raise RuntimeError('Provider job failed: '+spec['id'])
            save_images(response,folder)
            with LOCK:print('completed',spec['id'],'generations',charged(response),flush=True)
            return
        time.sleep(5)
    raise RuntimeError('Polling deadline reached; resume the saved job ID: '+spec['id'])


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--manifest',type=Path,default=ROOT/'scripts/pixellab_redesign/static-manifest.json');parser.add_argument('--only',nargs='*');parser.add_argument('--dry-run',action='store_true');args=parser.parse_args()
    manifest=json.loads(args.manifest.read_text());raw=ROOT/manifest['rawDir'];raw.mkdir(parents=True,exist_ok=True)
    jobs=[spec for spec in manifest['jobs'] if not args.only or spec['id'] in args.only]
    if args.dry_run:
        print(json.dumps({'jobs':len(jobs),'requestedGenerations':sum(j['estimatedGenerations'] for j in jobs),'alreadyChargedOrReserved':committed_cost(raw),'ceiling':manifest['maxGenerations']}));return
    token=api.token();waiting=iter(jobs);error=None
    with concurrent.futures.ThreadPoolExecutor(max_workers=manifest['concurrency']) as pool:
        active={}
        for _ in range(manifest['concurrency']):
            spec=next(waiting,None)
            if spec:active[pool.submit(generate,spec,manifest,raw,token)]=spec['id']
        while active:
            done,_=concurrent.futures.wait(active,return_when=concurrent.futures.FIRST_COMPLETED)
            for future in done:
                name=active.pop(future)
                try:future.result()
                except Exception as exc:
                    write(raw/'batch-error.json',{'id':name,'error':str(exc),'type':type(exc).__name__})
                    code=re.search(r'HTTP (\d+)',str(exc));print('stopped',name,type(exc).__name__,code.group(1) if code else '',flush=True);error=exc
                if error is None:
                    spec=next(waiting,None)
                    if spec:active[pool.submit(generate,spec,manifest,raw,token)]=spec['id']
    if error:raise SystemExit(1)
    print('batch complete; charged or reserved generations across this task:',committed_cost(raw))

if __name__=='__main__':main()
