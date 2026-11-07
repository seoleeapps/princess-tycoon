"""커밋한 아틀라스·참조·실제 청구 명세 검증. NAS 원본이나 API 키가 필요 없다."""
import hashlib,json,sys
from pathlib import Path
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'godot/assets/pixellab_v2'
def main():
 data=json.loads((ART/'catalog.json').read_text());receipt=json.loads((ART/'provenance.json').read_text());errors=[]
 if not receipt['complete']:errors.append('Preview assets are not a production candidate')
 total=sum(float(job.get('generations') or 0) for job in receipt['jobs'])
 if total!=receipt['actualGenerations'] or total>receipt['maximumGenerations']:errors.append('Billing total or ceiling mismatch')
 for spec in receipt.get('files',[]):
  path=ART/spec['path']
  if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest()!=spec['sha256']:errors.append('Product hash mismatch: '+spec['path'])
 for category,count in [('bodies',5),('enemies',15),('backgrounds',9),('gear',9)]:
  if len(data[category])!=count:errors.append('Catalog count: '+category)
 for category in ['bodies','enemies']:
  for name,clips in data[category].items():
   expected=['idle','walk','attack'] if category=='bodies' else ['idle','attack','defeat']
   if sorted(clips)!=sorted(expected):errors.append('Clip names: '+name)
   for clip,spec in clips.items():
    image=Image.open(ART/spec['path']).convert('RGBA');size=(1152,1024 if category=='bodies' else 128)
    if image.size!=size:errors.append('Size: '+name+clip);continue
    frames=[image.crop((128*i,0,128*(i+1),128)) for i in range(9)]
    if len({frame.tobytes() for frame in frames[:8]})<3:errors.append('Motion is static: '+name+clip)
    for index,frame in enumerate(frames):
     alpha=frame.getchannel('A').point(lambda value:255 if value>128 else 0);box=alpha.getbbox()
     if not box or box[0]<=0 or box[1]<=0 or box[2]>=128 or box[3]>=128:errors.append(f'Clipped/empty {name} {clip} {index}: {box}')
    if category=='bodies' and len(spec['anchors'])!=9:errors.append('Anchors: '+name+clip)
 for key,spec in data['gear'].items():
  if Image.open(ART/spec['path']).size!=(1152,384):errors.append('Gear atlas: '+key)
 for env,path in data['backgrounds'].items():
  if Image.open(ART/path).size!=(192,176):errors.append('Background size: '+env)
 for error in errors:print('[FAIL]',error)
 print(f'PixelLab assets: {len(errors)} errors; actual {total:g} / {receipt["maximumGenerations"]} generations')
 return 1 if errors else 0
if __name__=='__main__':sys.exit(main())
