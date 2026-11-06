# 활동·환경 픽셀 애니메이션

사용자가 2026-11-06 전달한 「PixelLab 픽셀 애니메이션 8종 적용」 계획의 구현 지시가 승인 근거다. 기준은 `aa74dca59f8ff5595510d6187d766ac026317882`이며 완료 지점은 main 병합이다. 기존 아카데미 방 방향 A, 화면 배치, 수련생 페이퍼돌과 장비·성장색을 유지한다. 새 화면이나 UI 개편은 없다.

| 조건 | 클립 | 속도 |
|---|---|---|
| education, magic 태그 없음 | book | 6fps |
| education, magic 태그 있음 | magic | 6fps |
| job | ledger | 6fps |
| rest | tea | 6fps |
| adventure | compass | 6fps |
| challenge 또는 exam/sport/contest/league | flag | 6fps |
| academy/library | candle | 4fps |
| city/forest | leaves | 4fps |

`activeTask.activityId`로 실제 활동 descriptor의 kind와 tags를 읽는다. 활동이 없으면 도구를 숨긴다. 도구는 수련생 오른쪽 바닥, 환경은 왼쪽 장면에 놓고 얼굴·장비·말풍선·입력을 침범하지 않는다. 64×64의 아트 픽셀은 논리 128×128로 nearest 확대한다.

주 화면이 UI 전용 재생기를 소유한다. 같은 활동 ID의 홈 재생성은 시간을 보존하며 활동 전환은 도구 시간만 초기화한다. 일시정지, 오프라인 정산 대기, 앱 비활성, 홈 이탈은 모든 장면 시간을 멈춘다. 모션 줄이기는 원본 참조 프레임을 표시하고 시간을 보존한다. 이 상태는 저장·게임 난수에 들어가지 않는다. 누락·잘못된 크기의 텍스처는 표시하지 않으며 게임 동작은 계속된다.

기존 코드 도트와 warm 팔레트로 참조를 만든 뒤 PixelLab `animate-with-text-v3`에 같은 first_frame/last_frame과 no_background를 보낸다. 책부터 화면·반복 연결을 확인하고 나머지를 제작한다. 클립마다 최초 1회와 품질 재생성 1회, 총 128 generations 상한이다. 공식 문서의 현재 64×64·8프레임 예상은 1 generation이지만 실제 잔액 차감을 기록한다. 다른 실행의 동시 차감 가능성도 별도 표시한다. 최종 시트·정지 참조·manifest는 `godot/assets/pixel_animations/`에서 관리하고 기존 생성기를 건드리지 않는다.

검증 PA-01은 선택·전환·없는 활동, PA-02는 시간·정지·재개·홈 재진입, PA-03은 에셋 크기·투명·누락, PA-04는 장비 합성·실행 화면·입력이다. 동작은 먼저 실패하는 headless 테스트로 확인한다. 생성 이미지 품질은 TDD 대신 접촉 시트와 세 viewport의 전체 루프 렌더를 직접 본다. 기존 `npm test`, headless/렌더링 E2E, Web export를 실행하고 로그 오류도 검사한다.

로컬 모델 리뷰와 실제 required check 확인 뒤 한국어 Ready PR을 병합한다. 중앙 계약은 참고 형식이며 이 `seoleeapps` 저장소는 Seorilabs 중앙 릴리스 검증 대상이 아니다. `release: null`이며 기기와 마켓 작업은 없다. 원본·검수 자료는 확인된 NAS1dual/Data로 스트림 복사하고 크기·SHA-256·목록 검증 뒤 로컬에서 정리한다. 복구는 PR revert이며 저장 마이그레이션은 없다.
