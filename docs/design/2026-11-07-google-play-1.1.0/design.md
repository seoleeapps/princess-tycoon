# Google Play 1.1.0 업데이트 출시

2026-11-07 사용자 지시 「구글 플레이 버전 출시 진행하고 세션 종료하자」를 승인 근거로 main `85dd49c1715862d139557de782bbd09cb1f752e6`에 완료된 새 PixelLab 아트·장면 중심 모험·목표 안내·직접 학습 후 자동 진행·안전 영역 수명 오류 수정을 Google Play에 출시한다. 앞선 구현 계획의 release:null 이후 받은 별도 출시 승인으로, 기존 구현·검수 기록은 보존한다.

기존 Seolee Apps 개인 계정5547060480954653351, 패키지com.seoleeapps.princesstycoon, 한국 무료100% 배포, 광고·결제·서버·분석 SDK 없음과 기존 관리형 게시 설정을 유지한다. Console의 계정·소유와 API의 기존 bundle code1~3을 확인했다. 새 버전은 기능 추가를 반영한1.1.0, code4다.

이 seoleeapps 저장소는 기존 승인된 docs/google-play-release.md의 수동 출시 레인을 사용한다. 중앙 release-tag/deploy caller·원장 브랜치를 새로 만들지 않으며 중앙 조직 출시 검증 통과로 표시하지 않는다. export 버전·Play config·새 원장을 함께 고치고 Ready PR로 병합한 후보에 annotated v1.1.0 태그를 만든다. 기존1.0.1 원장은 history에 보존한다.

이번 변경은 출시 버전과 실제 화면·등록 문구뿐이며 게임 코드·아트·규칙·SDK·권한·저장 형식·엔진은 바꾸지 않는다. L1/dev, redesign:false. 같은 후보 SHA에서 npm test(19smokes), test:e2e와 capture:e2e(390×844/430×932/720×1280), balance, Web export, Play config 검사, Android AAB 빌드를 실행한다. 현재 화면으로 실제 스토어 스크린샷을 다시 캡처한다. 버전/문구에 동작 TDD를 만들지 않고 manifest의 패키지·버전·SDK·권한·ABI, 업로드 인증서·포함 리소스·API 수신 해시를 대조한다. 기존 UI 개편3회 검수는 이전 구현 근거로 남기며 이번 출시를 새 UI 개편이나 새 독립 검수로 세지 않는다.

개발 환경으로 확인할 수 없는 새 네이티브 필수 항목이 없어 기기를 사용하지 않는다. 최초 출시의 AND-01~07 기록을 현재 후보 기기 실행으로 표시하지 않는다. 기존 custom Theme의 별도 정적 UI 스캐너7 FAIL 기록도 덮지 않는다.

같은 AAB를 내부 테스트에 게시한 뒤 정확한 버전과 처리 상태를 읽고 한국 프로덕션으로 승격한다. 출시 노트, 실제 스토어 설명·그림·국가·정책·관리형 게시와 제출 ID를 재조회한다. changesInReviewBehavior=ERROR_IF_IN_REVIEW로 기존 심사를 임의 취소하지 않는다. 제출과 승인·공개는 별도다. 심사가 오래 걸리면 마지막 제출 ID·조회 시각·승인 뒤 자동/수동 전환을 원장에 남기고 이번 사용자 요청대로 브라우저·worktree·임시 산출물을 정리해 세션을 종료한다. 상시 모니터를 만들거나 감시를 약속하지 않는다.

모든 실행 원본·AAB·API/Console readback은 NAS1dual/Data로 스트림 복사하고 ZIP 내부까지 크기·SHA-256을 대조한 뒤 로컬에서 정리한다. 등록용 실제 스크린샷과 코드·짧은 실행 기록만 Git에 남긴다.
