"""검토용 화면 시안. 런타임과 분리되며 실제 게임 상태/보상을 만들지 않는다."""
from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts/pixel_art'))
from pixellib import Art, Screen, rgb
import icons, scenes, trainee, ui_kit as K
from PIL import Image, ImageDraw

S = K.STYLES['wood']

def base():
    a = Art(195, 422, S['strip_lo'])
    K.wood_strip(a, 0, 0, 195, 27)
    K.button(a, 5, 3, 22, 22, 'secondary', S)
    a.blit(icons.icon('menu'), 12, 10)
    a.blit(icons.icon('coin'), 154, 8)
    return a

def label(sc, x, y, text, width=366, title=False, color=None):
    size = 24 if title else 16
    assert sc.measure(text, 'title' if title else 'body', size) <= width, text
    sc.text(x, y, text, role='title' if title else 'body', size=size, color=color or S['text'])

def header(sc, date='1연차 · 1시즌 · 첫날'):
    label(sc, 66, 5, '세라', width=100, color=S['on_strip'])
    label(sc, 66, 28, date, width=230, color=S['on_strip_muted'])
    label(sc, 330, 17, '2.8천', width=56, color=S['on_strip'])

def figure(a, x, y, equipped=True):
    equipment = {'outfit':'OUTFIT_ACTIVE','armor':'ARM_PLATE','weapon':'WPN_SWORD'} if equipped else {}
    img = trainee.compose('explorer' if equipped else 'balanced', equipment, 'focus')
    a.blit(img, x - trainee.OX, y - trainee.OY)

def golem(a, x, y):
    edge, lo, mid, hi = map(rgb, ['263c35','3f6151','69846a','99ad86'])
    a.rect(x+6,y+9,24,28,edge); a.rect(x+8,y+11,20,23,mid)
    a.rect(x+10,y,17,15,edge); a.rect(x+12,y+2,13,11,hi)
    a.rect(x,y+13,9,21,edge); a.rect(x+2,y+15,5,14,lo)
    a.rect(x+28,y+12,9,22,edge); a.rect(x+30,y+14,5,15,mid)
    for dx in [8,22]: a.rect(x+dx,y+34,9,9,edge);a.rect(x+dx+2,y+35,5,6,lo)
    a.rect(x+14,y+7,3,2,rgb('f3d66c')); a.rect(x+21,y+7,3,2,rgb('f3d66c'))
    a.rect(x+9,y+11,8,4,rgb('43874d'));a.rect(x+24,y+18,6,7,rgb('43874d'))
    a.rect(x+16,y+21,7,6,rgb('9ed4b5'));a.rect(x+18,y+22,3,4,rgb('e2efd0'))

def home(out):
    a = base()
    K.parchment(a,4,31,187,58)
    K.gauge(a,10,77,175,6,0,K.METER_COLORS['reputation'],S['gauge_bg'],S['outline'])
    a.blit(scenes.study_room(187,133),4,94)
    figure(a,87,157,False)
    a.blit(icons.icon('activity'),98,138)
    K.parchment(a,8,98,179,15)
    K.parchment(a,8,211,179,14)
    K.parchment(a,4,232,187,31)
    for i,key in enumerate(['energy','stress','reputation']):
        a.blit(icons.icon(key),9+i*62,237)
        K.gauge(a,10+i*62,252,52,5,[1,0,.5][i],K.METER_COLORS[key],S['gauge_bg'],S['outline'])
    K.parchment(a,4,269,187,49)
    K.button(a,4,325,187,28,'primary',S)
    K.button(a,4,359,187,24,'secondary',S)
    K.wood_strip(a,0,389,195,33)
    a.blit(icons.icon('home'),44,394);a.blit(icons.icon('activity'),143,394)
    sc=Screen(a);header(sc)
    label(sc,18,70,'첫 목표 · 시즌 심사 받기',title=True)
    label(sc,18,106,'진로 칭호를 모으며 수련생을 키워요.')
    label(sc,18,134,'심사까지 28일 · 오늘은 0 / 28일')
    label(sc,20,200,'지금 · 왕립 교양학')
    label(sc,20,426,'수업은 자동 진행돼요 · 잠시 뒤 결과 확인')
    for i,t in enumerate(['에너지 100','스트레스 0','평판 50']):label(sc,46+i*124,476,t,width=95)
    label(sc,18,548,'다음 할 일 · 첫 아르바이트 열기')
    label(sc,18,578,'활동 3회 완료  0 / 3')
    label(sc,18,606,'활동으로 성장하고 심사에 도전해요.')
    label(sc,124,668,'활동 살펴보기',color=S['primary_text'])
    label(sc,124,730,'지금 활동 마치기')
    label(sc,88,818,'홈');label(sc,284,818,'활동')
    sc.save(out/'home.png')

def adventure(out, mode):
    a=base()
    K.parchment(a,4,31,187,48)
    for i,state in enumerate(['secondary','gold','disabled']):
        K.button(a,8+i*63,57,53,19,state,S)
    if mode=='A':
        a.blit(scenes.forest(187,175),4,85)
        figure(a,36,181);golem(a,132,182)
        K.parchment(a,8,92,84,27);K.parchment(a,105,92,82,27)
        K.gauge(a,13,112,73,4,260/320,K.METER_COLORS['energy'],S['gauge_bg'],S['outline'])
        K.gauge(a,110,112,71,4,44/105,K.METER_COLORS['stress'],S['gauge_bg'],S['outline'])
        # A small hit effect, independent from rules. The numbers are design-example data.
        a.poly([(120,205),(123,197),(125,204),(131,201),(127,208),(132,212),(123,211),(120,219),(118,211),(112,213),(117,207),(112,202)],rgb('ffe9a1'))
    else:
        a.blit(scenes.forest(187,175),4,85)
        path=[(36,116),(132,171),(62,227)]
        for p,q in zip(path,path[1:]):
            a.d.line([p,q],fill=rgb('674b31'),width=9);a.d.line([p,q],fill=rgb('d6b988'),width=5)
        for i,(x,y) in enumerate(path):
            a.ellipse(x-12,y-12,x+12,y+12,S['outline']);a.ellipse(x-10,y-10,x+10,y+10,[S['primary'],S['gold'],S['disabled']][i])
            a.blit(icons.icon(['world','world','record'][i]),x-6,y-6)
        figure(a,101,143);golem(a,145,154)
        K.parchment(a,8,91,88,22);K.parchment(a,93,229,94,27)
    K.parchment(a,4,266,187,48)
    K.parchment(a,4,321,187,29)
    K.button(a,4,356,187,28,'primary',S)
    K.button(a,4,390,187,26,'secondary',S)
    sc=Screen(a);header(sc,'1연차 · 3시즌 · 1일')
    label(sc,18,70,'은잎 숲 탐사',title=True)
    label(sc,28,123,'탐색 완료',width=100);label(sc,152,123,'조우 2/3',width=100);label(sc,286,123,'보스',width=95,color=S['disabled_text'])
    if mode=='A':
        label(sc,24,190,'세라 260/320',width=158);label(sc,220,190,'골렘 44/105',width=150)
        label(sc,244,371,'23',title=True,width=100,color=rgb('fff4d6'))
    else:
        label(sc,26,190,'탐색 완료',width=160)
        label(sc,198,464,'골렘 44/105',width=170)
        label(sc,198,491,'세라 260/320',width=170)
    label(sc,18,542,'조우 · 이끼 수호 골렘',title=True)
    label(sc,18,578,'수련생이 골렘을 공격했어요.')
    label(sc,18,606,'23 피해 · 전투가 자동으로 이어져요.')
    label(sc,18,654,'탐색에서 찾은 지도 조각을 챙겼어요.')
    label(sc,18,678,'전리품은 원정 결과에서 확인해요.')
    label(sc,130,730,'결과 바로 보기',color=S['primary_text'])
    label(sc,164,799,'홈으로')
    sc.save(out/f'adventure-{mode}.png')

def main():
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    home(args.out)
    for mode in ['A','B']:adventure(args.out,mode)
    sheet=Image.new('RGB',(1218,932),'#f5eee2');d=ImageDraw.Draw(sheet)
    from pixellib import font
    for i,(name,title) in enumerate([('home','공통 · 목표가 보이는 홈'),('adventure-A','A · 장면 중심 (추천)'),('adventure-B','B · 탐험 지도 중심')]):
        d.text((i*414+10,9),title,font=font('title',24),fill='#3a2414');sheet.paste(Image.open(args.out/f'{name}.png'),(i*414,48))
    d.text((10,903),'설계 시안 v1 · 수치와 장면은 예시이며 게임 구현 화면이 아닙니다.',font=font('body',16),fill='#3a2414')
    sheet.save(args.out/'comparison.png')
    print(args.out/'comparison.png')
if __name__=='__main__':main()
