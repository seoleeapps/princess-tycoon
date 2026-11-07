"""원본 프레임의 클리핑·프레임 수와 전체 모션 contact sheet를 남긴다."""
import json
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];RAW=ROOT/'build/pixellab-redesign';selections=json.loads((ROOT/'scripts/pixellab_redesign/selections.json').read_text())
rows=[];report=[]
for name,clips in selections['clips'].items():
 for clip,folder in clips.items():
  paths=sorted((RAW/folder).glob('variant-*.png'))
  if len(paths)<8:continue
  row=Image.new('RGBA',(1152,150),'#272b35');draw=ImageDraw.Draw(row);draw.text((2,1),name+' / '+clip,fill='white');issues=[]
  for i,p in enumerate(paths):
   image=Image.open(p).convert('RGBA');box=image.getchannel('A').point(lambda x:255 if x>128 else 0).getbbox()
   if not box or box[0]<2 or box[1]<2 or box[2]>126 or box[3]>126:issues.append({'frame':i,'bbox':box,'severity':'clipped' if not box or min(box[0],box[1],128-box[2],128-box[3])==0 else 'near_edge'})
   row.alpha_composite(image,(i*128,20))
  rows.append(row);report.append({'name':name,'clip':clip,'count':len(paths),'issues':issues})
for batch in range((len(rows)+11)//12):
 selected=rows[batch*12:(batch+1)*12];sheet=Image.new('RGBA',(1152,len(selected)*150),'#272b35')
 for y,row in enumerate(selected):sheet.paste(row,(0,y*150))
 sheet.convert('RGB').save(RAW/f'motion-contact-{batch:02d}.png')
(RAW/'motion-qa.json').write_text(json.dumps(report,indent=2)+'\n')
print('completed clips',len(rows),'flagged',[(r['name'],r['clip'],r['issues']) for r in report if r['issues']])
