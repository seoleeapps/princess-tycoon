# 화면 수명 밖의 포커스 알림 오류 수정

사용자가 Godot 실행 중 `_notification → _apply_safe_area`에서 null Viewport의 get_visible_rect 호출 오류를 보고했다. 기준 main은9e7f02f334449e0741001f28026575029b189eaa다. 이 버그 수정 요청을 승인 근거로 L1/dev, redesign:false, release:null로 재현·수정·한국어 Ready PR/main 병합까지 진행한다. 화면 구성과 게임 규칙·저장 형식·마켓·기기는 변경하지 않는다.

MainScreen은 초기화 전이나 트리에서 분리된 상태에도 포커스/복귀 알림을 받을 수 있지만 Viewport는 이때 없다. 알림의 focused/paused 상태 표시는 보존하고, 트리 진입·ready 완료·삭제 대기 아님을 확인한 뒤 화면/저장/엔진 작업을 한다. 안전 영역 콜백도 유효한 Viewport가 있는 동안만 처리한다. 정상 ready에서의 첫 여백 적용과 복귀 정산은 유지한다.

| 조건 | 재현·통과 기준 |
|---|---|
| SA-01 | 트리 진입 전 FOCUS_IN·RESUMED 및 안전 영역 직접 콜백에서 동일 오류 RED를 확인하고 수정 후 오류0. 초기화/저장 등 부수 효과 없음. |
| SA-02 | 정상 진입/ready의 실제 여백 적용, 포커스·복귀에서 여백 갱신과 기존 일시정지 복귀 처리 유지. |
| SA-03 | remove_child로 분리한 뒤와 queue_free 대기 중의 늦은 알림/콜백은 상태 플래그 외 UI·엔진·저장을 건드리지 않음. 실제 size_changed 연결의 늦은 호출도 검사. |
| SA-04 | 동일 후보의 npm test와 headless E2E, 실제 렌더링 여정3크기를 실행하고 SCRIPT ERROR·ERROR:·리소스 누락을 검사. 작성자 L1 검수와 로컬 코드 리뷰 후 병합한다. |

새 게임 초기화는 QA 저장 경로만 사용한다. 사용자 저장과 다른 Godot 프로세스에는 접근하지 않는다. 새 아트나 UI 개편이 없어 시안/독립3회는 해당하지 않는다. 원본 오류/테스트/화면은 NAS 복사와 내부 해시 검증 후 정리하고 위치를 PR·병합 메시지에 기록한다. 수정은 수명 검사와 nullable Viewport 처리로 제한하며 별도 호환 계층/재시도는 만들지 않는다.

근거: [Godot Node 수명과 get_viewport](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-get-viewport), 기존 safe_area.gd와 headless_smoke.gd의 안전 영역 검사. 중앙 최신 계약2bf7204159ced1cb0de2644f00485736bfea2173을 확인했으며 출시 검증 통과로 표시하지 않는다.
