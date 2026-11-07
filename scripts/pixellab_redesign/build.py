"""검수한 PixelLab 결과를 무손실 아틀라스와 장비 부착점으로 변환한다. API 호출 없음."""
import colorsys,hashlib,json,shutil
from pathlib import Path
from PIL import Image,ImageOps
ROOT=Path(__file__).resolve().parents[2];RAW=ROOT/'build/pixellab-redesign';OUT=ROOT/'godot/assets/pixellab_v2'
PROFILES={'balanced':None,'martial':0.01,'scholar':0.61,'artist':0.79,'leader':0.12,'care':0.42,'explorer':0.31,'prosperity':0.08}
CLIPS=['idle','walk','attack'];BACKGROUNDS=['academy','library','city','arena','forest','cave','ruins','volcano','rift']
def write(path,obj):path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
def skin(p):
 r,g,b,a=p;return a>128 and r>130 and r>g*1.15 and g>b*1.08 and max(r,g,b)-min(r,g,b)<150

def anchors(im):
 pts=[(x,y) for y in range(12,90) for x in range(128) if skin(im.getpixel((x,y)))]
 face=[(x,y) for x,y in pts if y<42]
 head=(round(sum(x for x,y in face)/len(face)),round(sum(y for x,y in face)/len(face))) if face else (65,28)
 hands=[(x,y) for x,y in pts if y>=max(44,head[1]+17)]
 mx=max((x for x,y in hands),default=76);hand=[(x,y) for x,y in hands if x>=mx-4]
 palm=[mx-2,round(sum(y for x,y in hand)/len(hand))] if hand else [76,65]
 return {'weapon':palm,'armor':[head[0]-2,head[1]+27],'accessory':[head[0]-12,head[1]+3]}
def recolor(im,hue):
 if hue is None:return im
 result=im.copy();px=result.load()
 for y in range(39,110):
  for x in range(128):
   r,g,b,a=px[x,y];h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
   if a>0 and s>.22 and not skin((r,g,b,a)) and not (h<.12 and v<.48):
    rgb=colorsys.hsv_to_rgb((hue+(h-.55)*.12)%1,s*.88,v);px[x,y]=tuple(round(c*255) for c in rgb)+(a,)
 return result

def frames(folder,source,required):
 paths=sorted((RAW/folder).glob('variant-*.png'))
 if len(paths)<8:
  if required:raise RuntimeError('Missing complete clip: '+folder)
  return [source.copy() for _ in range(8)]
 if len(paths) not in [8,9]:raise RuntimeError('Unexpected frame count: '+folder)
 return [Image.open(p).convert('RGBA') for p in paths[-8:]]

def build(required=True):
 selections=json.loads((ROOT/'scripts/pixellab_redesign/selections.json').read_text());catalog={'version':2,'frameSize':128,'frameCount':8,'referenceFrame':8,'fps':6,'profiles':list(PROFILES),'canvas':[208,160],'foot':[88,137],'bodyOffset':[24,16],'bodies':{},'enemies':{},'backgrounds':{},'gear':{}}
 if required:
  for clips in selections['clips'].values():
   for folder in clips.values():
    receipt=RAW/folder/'receipt.json'
    if not receipt.exists():raise RuntimeError('Selected clip is not complete: '+folder)
    if len(list((RAW/folder).glob('variant-*.png'))) not in [8,9]:raise RuntimeError('Invalid selected frame count: '+folder)
 OUT.mkdir(parents=True,exist_ok=True)
 previous=json.loads((OUT/'provenance.json').read_text()) if (OUT/'provenance.json').exists() else {'jobs':[],'actualGenerations':0,'maximumGenerations':576}
 previous['complete']=False
 write(OUT/'provenance.json',previous)
 for d in ['bodies','enemies','backgrounds','gear']:(OUT/d).mkdir(parents=True,exist_ok=True)
 shutil.copyfile(RAW/'hero/variant-00.png',OUT/'style-anchor.png')
 for env in BACKGROUNDS:
  source=RAW/('forest' if env=='forest' else 'region_'+env)/'variant-00.png'
  shutil.copyfile(source,OUT/'backgrounds'/f'{env}.png');catalog['backgrounds'][env]=f'backgrounds/{env}.png'
 for name,source_path in selections['sources'].items():
  source=Image.open(RAW/'selected'/f'{name}.png').convert('RGBA');human=name.startswith('OUTFIT_');target=catalog['bodies' if human else 'enemies'];target[name]={}
  for clip,folder in selections['clips'][name].items():
   images=frames(folder,source,required)+[source]
   grounded=human or name in ['EN_FOREST_VINE','EN_FOREST_SENTINEL','EN_FOREST_WARDEN','EN_CAVE_CRAB','EN_RIFT_ECHO','EN_RIFT_WEAVER','EN_RUIN_ARCHIVIST','EN_VOLCANO_CINDER','EN_VOLCANO_TORTOISE']
   if grounded:
    aligned=[]
    for im in images:
     box=im.getbbox();dy=121-box[3] if box else 0
     moved=Image.new('RGBA',(128,128));moved.paste(im,(0,dy));aligned.append(moved)
    images=aligned
   sheet=Image.new('RGBA',(128*9,128*(8 if human else 1)))
   for row,hue in enumerate(PROFILES.values() if human else [None]):
    for i,im in enumerate(images):sheet.paste(recolor(im,hue) if human else im,(128*i,128*row))
   path=f'{"bodies" if human else "enemies"}/{name}_{clip}.png';sheet.save(OUT/path,optimize=True)
   target[name][clip]={'path':path,'anchors':[anchors(im) for im in images]} if human else {'path':path}
 for spec in json.loads((ROOT/'scripts/pixellab_redesign/static-manifest.json').read_text())['jobs']:
  name=spec['id']
  if not name.startswith(('WPN_','ARM_','ACC_')):continue
  source=RAW/name/'variant-00.png'
  if not source.exists():
   if required:raise RuntimeError('Missing gear: '+name)
   continue
  im=Image.open(source).convert('RGBA');im=im.crop(im.getbbox())
  extent=52 if name.startswith('WPN_') else (31 if name.startswith('ARM_') else 12)
  im.thumbnail((extent,extent),Image.Resampling.NEAREST)
  # Weapon art has a diagonal blade. The grip sits one fifth of its bounding box from the lower left.
  pivot=(round(im.width*.22),round(im.height*.78)) if name.startswith('WPN_') else (im.width//2,im.height//2)
  canvas=Image.new('RGBA',(128,128));canvas.paste(im,(64-pivot[0],64-pivot[1]));sheet=Image.new('RGBA',(128*9,128*3))
  for c,clip in enumerate(CLIPS):
   for i in range(9):
    angle=([0,0,-12,-30,-40,-25,-10,0,0][i] if clip=='attack' else ([0,-3,0,3,0,-3,0,3,0][i] if clip=='walk' else 0)) if name.startswith('WPN_') else 0
    sheet.paste(canvas.rotate(angle,resample=Image.Resampling.NEAREST,center=(64,64)),(i*128,c*128))
  path=f'gear/{name}.png';sheet.save(OUT/path,optimize=True);catalog['gear'][name]={'path':path,'slot':'weapon' if name.startswith('WPN_') else ('armor' if name.startswith('ARM_') else 'accessory')}
 write(OUT/'catalog.json',catalog)
 provenance=[]
 for p in sorted(RAW.glob('*/response.json')):
  r=json.loads(p.read_text());usage=r.get('usage') or r.get('last_response',{}).get('billing_usage',{});provenance.append({'asset':p.parent.name,'jobId':r.get('id') or json.loads((p.parent/'submission.json').read_text()).get('background_job_id'),'status':r.get('status'),'generations':usage.get('generations')})
 write(OUT/'provenance.json',{'provider':'PixelLab','maximumGenerations':576,'actualGenerations':sum(float(p['generations'] or 0) for p in provenance),'jobs':provenance,'selection':'scripts/pixellab_redesign/selections.json','complete':required,'selectedClips':60,'qualityRetries':len(json.loads((ROOT/'scripts/pixellab_redesign/quality-retries.json').read_text())),'files':[{"path":str(path.relative_to(OUT)),"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"size":list(Image.open(path).size)} for path in sorted(OUT.rglob('*.png'))]})
 print('built',len(catalog['bodies']),'bodies',len(catalog['enemies']),'enemies',len(catalog['gear']),'gear; complete=',required)
if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args();build(not args.preview)
