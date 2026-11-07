"""검수한 정적 원본을 고정하고 PixelLab 모션 작업을 명세한다."""
import hashlib,json
from pathlib import Path
from PIL import Image,ImageOps
ROOT=Path(__file__).resolve().parents[2];RAW=ROOT/'build/pixellab-redesign'
selected={'OUTFIT_PLAIN':'hero/variant-00.png','EN_FOREST_WARDEN':'forest_boss/variant-03.png'}
for prefix in ['EN_','OUTFIT_']:
 for p in sorted(RAW.glob(prefix+'*')):
  if '__' not in p.name and (p/'receipt.json').exists():selected[p.name]=p.name+'/variant-00.png'
prepared=RAW/'selected';prepared.mkdir(exist_ok=True)
for name,path in selected.items():
 im=Image.open(RAW/path).convert('RGBA')
 if name=='EN_FOREST_VINE':im=ImageOps.mirror(im)
 im.save(prepared/(name+'.png'))
jobs=[]
pilot={'OUTFIT_PLAIN':{'idle':'anim_hero_idle','walk':'anim_hero_walk','attack':'anim_hero_attack'},'EN_FOREST_WARDEN':{'idle':'anim_boss_idle','defeat':'anim_boss_defeat'}}
clips={}
for name in selected:
 clips[name]={}
 for clip in (['idle','walk','attack'] if name.startswith('OUTFIT_') else ['idle','attack','defeat']):
  if clip in pilot.get(name,{}):clips[name][clip]=pilot[name][clip];continue
  job=name+'__'+clip;clips[name][clip]=job
  human=name.startswith('OUTFIT_')
  action=({'idle':'Standing relaxed, subtle breathing and gentle hair and cloth movement. Feet planted. Seamless loop.', 'walk':'Walking in place facing right, clear alternating steps, natural arm swing and cloth sway. Seamless loop.', 'attack':'Facing right, make one clear forward hand thrust with the front arm, lean forward then return to the exact starting pose. Empty hands. No weapon or effects.'} if human else {'idle':'Subtle breathing and natural body motion, facing left. Feet stay grounded. Seamless loop.', 'attack':'Facing left, make one clear short forward attack lunge, then recover to the exact starting pose. Keep the full body and all limbs on canvas. No projectiles, no new props.', 'defeat':'Facing left, recoil from defeat then sink gently onto the ground and remain still in a defeated resting pose. Keep the same creature identity, full body visible. Do not vanish.'})[clip]
  jobs.append({'id':job,'kind':'animation','endpoint':'/animate-with-text-v3','source':'selected/'+name+'.png','action':action,'seed':int(hashlib.sha256(job.encode()).hexdigest()[:8],16)%(2**31),'returnToStart':clip!='defeat','estimatedGenerations':2})
quality_path=ROOT/'scripts/pixellab_redesign/quality-retries.json'
quality=json.loads(quality_path.read_text()) if quality_path.exists() else {}
for original,decision in quality.items():
 spec=next(job for job in jobs if job['id']==original).copy()
 spec.update(id=original+'__retry',action=decision['action'],seed=spec['seed']+1)
 jobs.append(spec)
 subject,clip=original.split('__')
 clips[subject][clip]=spec['id']
manifest={'provider':'PixelLab','apiVersion':'v2','maxGenerations':576,'concurrency':4,'qualityRetriesPerAsset':1,'rawDir':'build/pixellab-redesign','jobs':jobs}
(ROOT/'scripts/pixellab_redesign/animation-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(ROOT/'scripts/pixellab_redesign/selections.json').write_text(json.dumps({'sources':selected,'mirrored':['EN_FOREST_VINE'],'clips':clips},indent=2)+'\n')
print(len(jobs),'new clips',sum(j['estimatedGenerations'] for j in jobs),'generations')
