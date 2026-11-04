# 픽셀 육성·생활 시뮬레이션 실제 화면 조사

확인일 2026-11-04. 공식 스토어 스크린샷만 사용했다. 다른 게임의 이미지는 저작물이라 저장소에 넣지 않고 출처 URL과 분석만 남긴다.

| 게임 | 플랫폼·출시 | 출처 |
|---|---|---|
| Pocket Academy 3 (Kairosoft) | iOS·Android 세로, App Store 2022-08-16, Steam 2023-07-17 | [App Store](https://apps.apple.com/us/app/pocket-academy-3/id1623111026) iPhone 5.5인치 스크린샷 1~4 |
| Stardew Valley 모바일 | iOS·Android 가로, iOS 2018-10-24 | [App Store](https://apps.apple.com/us/app/stardew-valley/id1406710800), [개발사 프레스킷](https://www.stardewvalley.net/press/), 창 재질은 [Steam](https://store.steampowered.com/app/413150/) |
| Fields of Mistria (NPC Studio) | PC, Steam 1.0 2026-08-05 | [Steam](https://store.steampowered.com/app/2142790/) 스크린샷 0·3·6·12 |

2025~2026년 육성 시뮬레이션(Magical Princess, Machine Child, Princess Maker: Children of Revelation)과 Little Witch in the Woods도 Steam 공식 스크린샷으로 확인했다. 앞의 셋은 일러스트 UI이고, Little Witch in the Woods는 장면만 픽셀이고 창은 고해상도 그림이라 픽셀 UI 레퍼런스에서 뺐다.

## 관찰

- **Pocket Academy 3**: 장면이 화면 높이의 약 71%이고 위 HUD 띠가 약 13%, 아래 명령 패널이 약 15%다. 1 아트픽셀은 약 1.5pt로 화면 폭이 약 270 아트픽셀이다. 결과는 화면 가운데 창 안의 작은 장면과 "아이콘 ×수량" 한 줄로 보여 준다. HUD에 숫자 8개가 몰려 영어 라벨이 잘리고, 그라데이션 버튼이 픽셀 재질과 섞인다.
- **Stardew Valley 모바일**: 장면이 약 93%이고 정보는 모서리 판에만 둔다. 숫자는 3~5개뿐이다. 상태는 물체 위 말풍선 아이콘으로 알리고, 에너지는 숫자 없는 막대로만 보여 준다. 대화창은 본문 칸과 초상화 칸, 두루마리 이름판으로 나뉜다.
- **Fields of Mistria**: 1080p에서 1 아트픽셀이 4px이고 UI와 장면이 같은 정수 배율이다. 창은 단색 면에 1픽셀 외곽선, 위 하이라이트 1픽셀, 아래 그림자 1픽셀을 넣고, 테두리에 주제 패턴을 쓴다. 본문까지 모두 픽셀 폰트다. 요리 창은 아이콘 탭, 목록, 상세, 수량 조절, 확인 버튼 순서로 나뉜다.

## 우리 게임에 쓰는 원리

1. 장면을 크게 두고 HUD는 얇은 띠로 둔다(PA3). 수련생이 무엇을 하는지가 먼저 보여야 한다.
2. 재질 규칙 하나와 정수 배율 하나로 창, 버튼, 장면을 통일한다(FoM).
3. 지금 하는 활동은 수련생 머리 위 말풍선 아이콘으로 보여 준다(Stardew).
4. 결과는 창 안의 작은 장면과 "아이콘 + 변화량" 한 줄로 보여 준다(PA3).
5. 목록은 아이콘 탭, 목록, 상세 시트로 나눈다(FoM). 목록 행에는 이름과 핵심 수치만 둔다.

## 맞지 않는 점

- 가로형 모서리 HUD, 10칸 핫바, 키 힌트는 세로형 방치 게임에 맞지 않는다.
- FoM 밀도를 390pt 폭에 옮기면 칸이 약 27pt로 터치 최소 44pt보다 작다. 한글은 획이 많아 영문 픽셀 폰트처럼 작은 높이로 쓰지 않는다(본문 16px 유지).
- PA3의 학교 전경은 학생 수십 명을 보는 구도라, 수련생 한 명에 집중하는 우리 게임과 다르다.
