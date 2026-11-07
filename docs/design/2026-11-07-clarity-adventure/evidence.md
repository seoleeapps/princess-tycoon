# 설계 단계 확인과 증적

- 개선 설계 v1: `2b3a21ee63bf2aba11b1a57b9c2564d87169592b`. 제품 실행 코드 변경 없음, 사람의 A·B 선택과 설계·테스트 계획 확인 대기.
- 기존 화면 기준: `6232e9c5d177900b830ab20eac3ad1f2d58b50fa`. `E2E_VIEWPORTS=390x844 ... npm run capture:e2e` 종료 0, 2개 여정 153단계, PNG 25장. 새 게임과 월드 원정 결과를 직접 확인했다. 이는 기존 동작의 관찰이며 제안한 개선의 통과 증거가 아니다.
- 첫 홈: 목표나 플레이어 역할 안내가 없고 자동 진행과 수동 즉시 실행의 차이를 설명하지 않는다. 월드 원정: 성공 창이 목록 위에 떠 3노드 과정과 적 이름이 잘린다. 이 관찰을 `design.md`의 변경 근거로 사용했다.
- 시안 렌더: `render_mockups.py --out build/clarity-adventure/mockups` 종료 0. 공통 홈과 같은 지역·같은 조우 상태의 A·B 비교. 기존 폰트의 미지원 체크 표시·화살표를 제거하고, 장면 위 글자는 양피지 바탕에 잉크색으로 고쳤다. PNG는 설계용 예시이며 아직 게임에 연결하지 않았다.
- 문서 검사: `npm run check:docs`와 `git diff --check` 통과. 최신 중앙 test-plan schema에 대한 Draft202012Validator 검사도 통과했다. 기본 Python에는 jsonschema가 없어 격리된 uv 실행 환경을 사용했다.
- 심볼 분석: Serena의 GDScript 연결 초기화가 실패해 심볼 도구 결과를 근거로 쓰지 않았다. 실제 프로젝트의 해당 함수와 데이터 파일을 범위를 좁혀 읽고, 실제 렌더링으로 확인했다. 직접 시작한 창 없는 Godot 편집기 PID 17712는 종료했다. 기존 프로세스와 기기는 사용하지 않았다.
- 개선 코드 테스트, 5지역·15적 제작, 모션·소리·접근성·전후 결정성 비교, 독립 L3 전체 검수 3회는 아직 미실행이다. 새 화면 구현 전 선택·설계 승인이 필요하다.

NAS: `/Volumes/Data/Backup/agent-artifacts/princess-tycoon/2026-11-07/2b3a21ee63bf2aba11b1a57b9c2564d87169592b/clarity-adventure-design-v1/`

`artifacts.zip`은 38개 파일, 655,424 bytes이며 SHA-256은 `1dff503dd953e4af9ea41b478a9862638e13ad558a07cea789efe7fcc6e118b8`이다. NAS 사본의 전체·내부 파일명·크기·SHA-256을 읽어 대조했다. 사람의 시안 선택에 필요한 `comparison.png`도 같은 위치에 따로 두고 바이트·SHA-256을 확인했다(`5269b00def0d3686ebc1b1d1390ace4af6ff97ebce85911d81ca5f953603af1a`).

마지막에 작성해 다시 읽은 `MANIFEST.json`의 SHA-256은 `c3821eb774fcdc4c79fd2394be0d7e952015721ab0b45112e24a729d296d487e`다. 보존 만료는 지정하지 않았다. 확인 시각은 2026-11-07T02:09:03Z다. 검증을 마친 로컬 캡처·조사 이미지·압축본은 정리하고, 작은 설계 원본과 재현 소스는 작업 브랜치에 보존한다.
