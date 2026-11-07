# 1.0.1 Google Play 배포 실행

2026-11-07 09:15 KST 확인 기준, **1.0.1(3)은 내부 테스터에게 제공되고 프로덕션 제출 ID 2는 검토 중**이다. Google 승인, 1.0.1 공개와 공개판 확인은 남아 있다. 관리형 게시가 꺼져 있어 승인 뒤 자동 공개되는 설정이다. 공개 완료를 선언하거나 새 기기 검수를 수행하지 않았다.

## 후보와 빌드

출시 준비 PR #21을 병합한 `1953abaad55df233a987ae05f4b5cfb83cdd9a1b`에서 실행했다. 실제 annotated tag `v1.0.1`도 같은 SHA를 가리킨다. 실행 전후 추적 파일은 그대로였고, 이 실행 기록은 빌드 이후 문서 PR로 반영한다. 패키지는 `com.seoleeapps.princesstycoon`, versionName은 `1.0.1`, versionCode는 `3`이다.

서명 AAB는 56,380,417 bytes이며 SHA-256은 `84527bdd81aae44f5d73e872809275caf12a5078f37a7c05d0acd6155efba1d6`이다. 실제 번들 manifest의 minSdk 24, targetSdk 36, debuggable false(속성 기본값), 권한 없음과 arm64-v8a·armeabi-v7a를 확인했다. 8종 시트·8종 참조의 import와 연결된 텍스처 16개가 있으며, extract·테스트·비밀 파일은 없다. ZIP CRC도 통과했다.

업로드 인증서 SHA-256은 `BB:CF:E8:D7:B9:D2:65:61:7A:B8:41:4A:DC:26:58:79:50:84:A2:06:ED:11:E9:07:37:C8:3B:6A:39:E3:13:65`이다. 기존 카탈로그·빌드 인증서와 이번 Console에서 내려받은 업로드 공개 인증서가 일치한다. 서명 키·계정·권한은 변경하지 않았다.

## 개발 환경 검증

모든 실행은 L1/dev, Godot 4.7.2, 같은 후보 SHA다.

| 명령 | 종료 코드 | 근거 |
|---|---:|---|
| `npm test` | 0 | 기존 전체 smoke와 애니메이션 68개 검사 PASS |
| `npm run test:e2e` | 0 | 390×844, 430×932, 720×1280 각각 153단계 PASS |
| `npm run test:balance` | 0 | 20개 검사 PASS |
| `npm run build:web` | 0 | Web release export 완료 |
| `npm run check:play` | 0 | ready |
| `npm run build:android` | 0 | 서명 AAB·인증서 검사 PASS |
| `npm run capture:e2e` | 0 | 세 화면 각각 153단계, 25 PNG |
| `npm run capture:animations` | 0 | 세 화면 각각 8종·120단계·72 PNG, 총 216 PNG |

54개 전체 로그에서 `SCRIPT ERROR`, `ERROR:`, Parse Error와 리소스 누락을 검사해 0건이었다. 실제 홈 화면과 세 화면의 8종×9프레임 contact sheet를 확인했으며, 반복 경계의 튐, 잘림, 얼굴·장비·말풍선·버튼 가림과 도트 흐림을 발견하지 못했다. 실제 좌표로 정지·재개 버튼 입력과 시계 정지도 통과했다. 코드·에셋은 이전 애니메이션 PR #19의 최종 결과와 같으며 출시 버전만 바꿨다.

처음 테스트를 감싼 zsh 명령에서 예약 변수 `status`에 종료 코드를 담으려다 wrapper가 실패했다. 실제 품질 로그는 PASS였지만, 올바른 bash wrapper로 전체 명령을 다시 실행해 위 종료 코드를 수집했다. AAB 파일 검사의 첫 가정(`.png.remap`)도 실제 export 형식(`.png.import`와 `.ctex`)에 맞춰 수정한 뒤 모든 연결을 확인했다. 초기 기록과 재실행 원본은 NAS에 보존했다.

기존 custom Theme 때문에 별도 `ui_gate` 정적 스캐너가 7 FAIL이었던 사실은 [이전 실행 기록](../2026-11-pixel-animations/execution.md)에 남아 있다. 이를 이번 통과로 바꾸지 않았다. 이번 변경에는 개발 환경으로 확인할 수 없는 새 네이티브 필수 항목이 없어 기기를 사용하지 않았으며, 최초 출시 AND-01~07을 새 후보의 기기 통과로 취급하지 않았다.

## 마켓 상태

실제 로그인 `wellknowngeek@gmail.com`, Seolee Apps 개인 계정 `5547060480954653351`과 대상 앱 소유를 확인했다. 활성 locale은 ko-KR 하나이고 제목·설명·연락처는 config와 같았다. Console 정책 상태는 발견된 문제 없음, 앱 콘텐츠의 주의 필요 항목은 없음이다. 국가 대한민국, 무료, 광고·인앱 결제 없음과 관리형 게시 사용 중지를 유지했다.

- 내부 테스트 edit `10456158908285424638`: 09:11 KST commit. API 수신 SHA-256이 로컬과 일치했고 새 edit 재조회도 `1.0.1 (3)`, completed다. Console은 활성 최신 출시·내부 테스터에게 제공됨을 표시했다. 신규 설치 크기 30.4MB, 지원 기기 18,579대, API 24 이상, target36, ABI2와 출시 노트도 확인했다.
- 프로덕션 edit `16731596098760486557`: 09:12:55 KST commit. 같은 code3과 출시 노트로 100% 전체 출시를 지정했다. `changesInReviewBehavior=ERROR_IF_IN_REVIEW`로 기존 심사를 임의 취소하지 않도록 했으며 새 edit 재조회로 확인했다.
- 실제 [제출 2 세부정보](https://play.google.com/console/u/0/developers/5547060480954653351/app/4975448277702761694/publishing/submission-activity/2/details)는 API, 2026-11-07 09:12 KST, 프로덕션 1.0.1 (3), 전체 출시 시작, 검토 중이다. 게시 개요에는 빠른 검사 후 자동 전송 안내가 함께 표시됐다.
- [한국 공개 스토어](https://play.google.com/store/apps/details?id=com.seoleeapps.princesstycoon&hl=ko&gl=KR)는 조회되지만 여전히 첫 출시 노트를 표시한다. 이는 1.0.1 공개 근거가 아니다. 기존 1.0.0(2) 제출1은 Console에서 출시됨으로 읽혔다.

원장 검사(`launch_ledger.py check`)는 구조 오류 0개이며 `complete: false`, 종료 1이다. 남은 관문은 `approval`, `release`, `live_smoke` 세 가지로, 모두 pending이다. 이 외부 대기를 테스트 실패나 공개 완료로 바꾸지 않았다. 이슈 #20은 공개 확인 전까지 열어 둔다. 별도 상시 모니터는 설정하지 않았다.

## 증적과 정리

NAS1dual/Data 실제 SMB 연결을 확인한 뒤 다음 새 폴더로 이관했다.

`/Volumes/Data/Backup/agent-artifacts/princess-tycoon/2026-11-07/1953abaad55df233a987ae05f4b5cfb83cdd9a1b/google-play-1.0.1/`

`artifacts.zip`에는 AAB, 전체 로그, API 응답, 실제 화면, Console 텍스트와 공개 인증서 등 422개 파일(압축 전 62,674,311 bytes)이 있다. ZIP은 60,860,029 bytes, SHA-256 `453f21ff483647184dc18ccc7752da5ab0f0826d05343bf5f7abc6318480ecc4`다. NAS 사본 전체와 내부 모든 파일의 이름·크기·SHA-256을 읽어 대조한 뒤 `MANIFEST.json`을 쓰고 다시 읽었다. MANIFEST SHA-256은 `fb6fc7f21cc4356f633a8b762302229b791e3d26795e7b22a5a504fc192678ad`다. NAS 보존 만료는 지정하지 않았다.

검수가 끝난 로컬 AAB·캡처·로그·작업용 Android Gradle 템플릿과 Web export는 정리한다. 브라우저는 자기 세션만 반납하고 인증 프로필·공용 도구·캐시·다른 작업은 보존한다. 원격 병합이 확인된 자신의 브랜치와 worktree만 제거한다.
