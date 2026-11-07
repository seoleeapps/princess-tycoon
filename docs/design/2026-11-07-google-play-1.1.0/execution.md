# Google Play 1.1.0 실행 결과

2026-11-07 21:41:42 KST 최종 조회에서 **1.1.0(4), 제출3은 정식 검토 중**이다. 앞선 빠른 검사는 끝났고, 관리형 게시가 꺼져 있어 승인 뒤 자동 공개된다. Google 승인, 새 버전 공개와 공개판 확인은 pending이다. 사용자의 「출시 진행하고 세션 종료」 지시에 따라 상시 모니터 없이 증적과 원장을 보존하고 이번 작업 세션을 정리한다. 공개 완료를 선언하지 않는다.

## 후보와 검증

출시 준비 PR #30을 병합한 `8f173840f912b7d99bca731a27af95e98cf89a34`가 실제 annotated tag `v1.1.0`와 빌드의 원본이다. 새 PixelLab 수련생과 배경·애니메이션, 장면 중심 모험, 목표 안내, 직접 학습 후 자동 진행, 조건부 정산 버튼과 null Viewport 수정을 포함한다. 이번 준비 PR은 버전·등록정보·화면만 바꿨으며 게임 코드를 추가 수정하지 않았다. 실행 기록 커밋은 빌드 뒤 문서 변경이다.

같은 후보에서 `npm test`(19smokes), `test:e2e`, `capture:e2e`, `test:balance`, `build:web`, `check:play`, `build:android`가 모두 종료0이다. headless와 실제 렌더링은 390×844, 430×932, 720×1280의6개 여정, 각169단계로 총1,014단계를 통과했다. 밸런스20개, 안전 영역 수명15개 검사도 통과했다. 실제 렌더 PNG81개를9개 컨택트시트로 직접 검수했고, 현재 화면으로 휴대전화6장·7인치4장·10인치4장을 다시 캡처해 확인했다. 엄격 로그 검사에서 SCRIPT ERROR·ERROR:·리소스 누락은0건이다.

AAB는59,462,800bytes, SHA-256 `6bf691ed17463443e8b5262b6b183687bb869c97af525a75e8df992c2ca1e755`이다. 실제 manifest에서 패키지 `com.seoleeapps.princesstycoon`, 1.1.0/code4, minSdk24, targetSdk36, debuggable false(기본값), 권한 없음과 arm64-v8a·armeabi-v7a를 확인했다. 소스의 새 아트79개 이미지와 연결된 imported texture79개, 기존 활동·환경16개 리소스, ZIP CRC와 jar 서명이 정상이다. extract·tests·env·jks·pem은 없다.

현재 Console에서 내려받은 업로드 공개 인증서가 AAB와 카탈로그의 SHA-256 `BB:CF:E8:D7:B9:D2:65:61:7A:B8:41:4A:DC:26:58:79:50:84:A2:06:ED:11:E9:07:37:C8:3B:6A:39:E3:13:65`와 일치한다. 키·계정·권한은 바꾸지 않았다. export 종료의 Scan thread aborted·ObjectDB1 경고와 자체 서명 업로드 인증서의 jar 경고는 원문에 보존했다. 초기 검증기의85개 이미지 가정은 실제 소스79개와 정확히 대조하도록 바로잡았다. 품질 로그는 기본 임시 폴더에 생성돼 실제 기록된 해당 폴더의21개 원본 로그를 증적 폴더로 옮겼다.

L1/dev, 기기 사용 없음이다. 새 네이티브 SDK·플러그인·권한·엔진·입력·저장 어댑터 변경은 없으며 최초 출시 AND-01~07을 새 후보의 기기 검수로 표시하지 않았다. 이전 UI 개편3회 검수와 별도 custom Theme 정적 UI 스캐너7FAIL 기록도 보존한다. 기존 seoleeapps 수동 출시 레인이며 중앙 조직 출시 검증을 통과했다고 주장하지 않는다.

## 실제 마켓 상태

실제 로그인 wellknowngeek@gmail.com, Seolee Apps 개인 계정5547060480954653351과 대상 패키지 소유를 확인했다. 한국 무료100%, 광고·인앱 결제 없음, ko-KR 한 언어를 유지했다. 현재 정책 상태는 발견된 문제 없음, 앱 콘텐츠의 주의 필요 항목은 모두 확인했습니다다. 개인정보처리방침·지원·한국 공개 스토어는 HTTP200이지만, 기존 공개 페이지 응답을1.1.0 공개 증거로 쓰지 않았다.

- internal edit `13783335075504534555`: 21:31:21 KST commit. API 수신 AAB 해시 일치, 새 edit 재조회와 Console의1.1.0(4)·내부 테스터에게 제공됨 확인.
- production edit `04058047743836210292`: 21:34:59 KST commit. 같은 code4와 출시 노트, 새 설명과 스크린샷14장을 한 edit로 제출했다. `changesInReviewBehavior=ERROR_IF_IN_REVIEW`로 기존 심사 취소를 막았다. 새 edit로 두 트랙의1.1.0(4), ko-KR 문구·출시 노트,14개 이미지 해시·순서와 국가KR를 대조했다.
- 실제 [제출3](https://play.google.com/console/u/0/developers/5547060480954653351/app/4975448277702761694/publishing/submission-activity/3/details): API, 2026-11-07 21:35 KST, 프로덕션1.1.0(4) 전체 출시 시작과 등록정보6개 변경, 검토 중. 21:41:42 KST 게시 개요에서 빠른 검사 안내가 사라지고 정식 검토 중임을 다시 확인했다. 관리형 게시 사용 중지다.

원장 `launch_ledger.py check`는 구조 오류0이며 종료1, `complete:false`다. 남은 관문은 approval·release·live_smoke의3개 pending이다. 이슈 #29는 실제 공개 확인 전까지 열어 둔다. 모니터나 알림은 설정하지 않았다.

## NAS와 정리

실제 NAS1dual/Data SMB 공유에 스트림 복사하고 압축본 전체와 내부230개 원본 파일의 크기·SHA-256을 직접 읽어 비교했다. `MANIFEST.json`은 마지막에 쓰고 다시 읽었다. 보관 만료는 지정하지 않았다.

`/Volumes/Data/Backup/agent-artifacts/princess-tycoon/2026-11-07/8f173840f912b7d99bca731a27af95e98cf89a34/google-play-1.1.0/`

- `artifacts.zip`:62,558,676bytes, SHA-256 `94caa12ffd19c021761cd11de793fe97a66ba747aedd747ed23c51caf942db1c`
- 최종21:41:42 조회와 갱신 원장 `final-readback.zip`:93,751bytes, SHA-256 `b5acf471df7e694f5e0dc649fabad570ac85d2419186242accefe66495847dc5`, 내부 파일까지 검증한 `final-readback-MANIFEST.json`

최종 병합·정리 확인은 같은 폴더의 검증된 작은 기록에 남긴다. 로컬 AAB·전체 로그·캡처·Web export·작업용 Android Gradle 템플릿과 Godot/Python 캐시를 정리하고, 자신의 브라우저 세션·브랜치·worktree만 반납한다. 사용자 저장·자격증명·공용 캐시·다른 세션은 보존한다.
