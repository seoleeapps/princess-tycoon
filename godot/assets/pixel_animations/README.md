# 활동·환경 프레임

기존 `assets/pixel/` 생성기와 분리한 PixelLab `animate-with-text-v3` 결과다. 참조는 `scripts/pixel_animations/references.py`가 기존 warm 방 팔레트와 수련생 팔레트로 그리며, 실제 프롬프트·seed·경로는 `scripts/pixel_animations/pixellab.json`에 있다. 원작 추출물은 사용하지 않았다.

| 파일 | 의미 | 재생 속도 |
|---|---|---|
| book.png | 책장 넘김 | 6fps |
| magic.png | 마법 구체 | 6fps |
| ledger.png | 작업 장부 | 6fps |
| tea.png | 찻잔의 김 | 6fps |
| compass.png | 탐험 나침반 | 6fps |
| flag.png | 대회 깃발 | 6fps |
| candle.png | 촛불 | 4fps |
| leaves.png | 잎사귀 | 4fps |

모두 64×64 RGBA 8프레임의 가로 시트(512×64), 투명 배경이다. `references/<이름>.png`는 모션 줄이기에서 표시하는 64×64 원본 참조다. 생성 시 같은 참조를 first_frame/last_frame에 보낸다. API가 반환한 9장 중 첫 참조 redraw를 빼고 8장을 시트로 만든다. 기준점은 프레임 내부 (32, 52)이며 모든 프레임의 캔버스를 유지한다. nearest로 정확히 2배 확대하고 수련생 페이퍼돌과 별도로 그린다.

화면의 최종 배치와 정지 조건은 `docs/design/2026-11-pixel-animations/`를 따른다. 완성 시트와 정지 참조만 런타임에 포함한다. API 원시 응답·개별 프레임·검수 캡처는 NAS에 보관한다. 실제 차감과 품질 지표는 `scripts/pixel_animations/pixellab-provenance.json`, 검수·보관 위치는 설계 폴더의 실행 기록에서 확인한다.
