# 실행 근거의 위치와 판정

이슈 [#18](https://github.com/seoleeapps/princess-tycoon/issues/18)의 인수조건은 설계 PA-01~04다. 테스트는 Godot 4.7.2, 개발 환경, 격리된 `user://qa_pixel_animation_*.json`과 E2E 전용 저장을 사용한다. 마켓 작업과 기기 사용은 없다.

생성은 8종 각 1회이며 품질 재생성은 없다. PixelLab 계정 잔액은 10,000 → 9,999 → 9,944로 감소했다. 기록한 실제 감소량은 총 **56 generations / 승인 상한 128**이다. 두 번째 구간의 55는 공유 계정 잔액의 차이이며 이 작업만의 개별 청구량과 동시 사용분을 분리할 정보는 없다. 공식 문서의 64×64·8프레임 예상 1과 구분하며, 차감 원인을 추정하지 않는다. 실제 프롬프트·참조·seed·품질 지표는 `scripts/pixel_animations/`에 보존했다.

완료 판정은 PR 본문의 명령별 결과와 NAS 원본 `result.json`을 함께 확인한다. NAS 보관 루트는 `/Volumes/Data/Backup/agent-artifacts/princess-tycoon/2026-11-06/<후보 SHA>/pixel-animations/`다. `MANIFEST.json`은 복사된 각 파일의 크기·SHA-256과 직접 재읽기 검증을 담는다. 보관 기간은 별도 삭제 승인 전까지다. 제품에서 사용하는 시트·정지 참조는 Git에 남기고 API 원본·검수 PNG·전체 로그·로컬 리뷰 출력은 NAS로 이관한다.

| 인수조건 | 실행 |
|---|---|
| PA-01 실제 활동의 종류·태그, 전환·활동 없음 | `pixel_animation_smoke.gd`와 실제 main 화면 fixture |
| PA-02 정지·재개·모션 줄이기·홈 재생성·앱 비활성 | 68개 smoke assertion, 전체 루프 캡처의 좌표 입력 |
| PA-03 64×64 8프레임·투명·누락·잘못된 크기·캐시 | smoke, 원본 접촉 시트와 실행 캡처 |
| PA-04 장비·성장색·게임 난수 보존, 잘림·가림·입력 | 기존 pixel 계약 검사, 3 viewport 전체 루프와 E2E |

최종 명령은 `npm test`, `npm run test:e2e`, `npm run capture:e2e`, `npm run capture:animations`, Web export와 브라우저 smoke다. 실패 원본을 통과로 덮지 않고 재실행 결과와 구분한다. 최초 TDD 실행은 재생기 부재로 실패했다. 첫 루프 검수 중 다른 Godot 실행이 포커스를 가져가 390×844와 430×932에서 정지한 기록도 보존하고, 렌더링 검수는 단독 실행한다.

추가 UI 정적 검사(`game-ui-commercial/ui_gate.py`)는 기존 custom Theme 구조에서 8항목 중 7 FAIL, 재화 칩 1 PASS였으며 기준 브랜치에서 동일한 보고서를 확인했다. 이를 통과로 바꾸지 않는다. 이 변경은 기존 방향의 활동 도구 추가로 한정하므로 ui_kit 전환은 수행하지 않는다. 실제 폰트·스킨·모션·입력 판정은 저장소의 pixel 계약과 실행 화면으로 확인한다.

`seoleeapps` 저장소는 Seorilabs 중앙 릴리스 계약의 강제 적용 대상이 아니며 `release: null`이다. 중앙 릴리스 검증 통과를 주장하지 않는다. 원격 ruleset·required check와 리뷰 상태는 PR HEAD에서 별도로 확인한다.
