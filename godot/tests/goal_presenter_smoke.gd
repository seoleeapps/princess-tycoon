extends SceneTree

const SOURCE := "res://src/ui/goal_presenter.gd"
var checks := 0
var failed := 0

func _initialize() -> void:
	if not ResourceLoader.exists(SOURCE):
		_check(false, "CL-01 홈 목표 표시기가 있어야 한다")
		quit(1)
		return
	var presenter: GDScript = load(SOURCE) as GDScript
	var state := _state()
	var unlock := {"stage": 1, "next": {"label": "아르바이트 3종", "remaining": {"activities": 3}}}
	var untouched := JSON.stringify(state)
	var result: Dictionary = presenter.describe(state, unlock)
	_check(result.headline.contains("시즌 심사"), "CL-01 첫 목표는 첫 시즌 심사")
	_check(result.progress == 0.0 and result.progress_label.contains("28"), "CL-02 첫날의 실제 28일 진행")
	_check(result.next_title.contains("아르바이트"), "CL-01 당장 할 일은 다음 해금")
	_check(result.action == "activity", "CL-02 열린 활동으로 안내")
	_check(JSON.stringify(state) == untouched, "CL-02 표시가 상태·보상을 바꾸지 않음")
	state.time.slot = 27
	result = presenter.describe(state, unlock)
	_check(is_equal_approx(result.progress, 27.0 / 28.0), "CL-02 심사 직전 일수")
	state.time.slot = 8
	state.unlocks.stage = 3
	result = presenter.describe(state, {"stage": 3})
	_check(result.action != "plan" and result.action != "auto", "MF-04 성장 방향 선택은 계획 탭에만 두고 학습 전 자동 권유 안 함")
	state.settings.guidanceSeen.append("first_direction")
	state.settings.guidanceSeen.append("auto_started")
	result = presenter.describe(state, {"stage": 3, "next": {"label": "시험", "remaining": {"slot": 6}}})
	_check(result.next_detail.contains("6일"), "CL-02 이미 고른 방향 안내 반복 안 함")
	state.settings.erase("guidanceSeen")
	result = presenter.describe(state, {"stage": 3})
	_check(result.action != "plan", "CL-03 기존 저장은 방향 선택 강제 안 함")
	state.time.slot = 56
	state.unlocks.stage = 6
	var previews: Array = [{"id": "END_ADVENTURER", "name": "왕국 탐사대원", "progress": 0.4, "missing": ["전투 100/300", "모험 0/18"], "stars": 0}]
	result = presenter.describe(state, {"stage": 6}, previews, {"forest_ready": true})
	_check(result.headline.contains("왕국 탐사대원") and result.progress == 0.4, "CL-02 현재 칭호 조건의 진행")
	_check(result.action == "world", "CL-02 첫 원정은 실제 열린 월드로 안내")
	result = presenter.describe(state, {"stage": 6}, previews, {"forest_ready": false, "forest_lock_reason": "체력 70 필요"})
	_check(result.next_detail.contains("체력 70") and result.action == "activity", "CL-02 참가 조건 부족을 숨기지 않음")
	state.forceRest = true
	result = presenter.describe(state, {"stage": 6}, previews, {"forest_ready": true})
	_check(result.next_detail.contains("휴식"), "CL-03 강제 휴식의 이유를 먼저 설명")
	state.forceRest = false
	state.lifetimeStats.adventures = 1
	previews[0].progress = 1.0
	previews[0].missing = []
	result = presenter.describe(state, {"stage": 7}, previews)
	_check(result.detail.contains("다음 심사"), "CL-02 조건을 채워도 심사 전 지급 안 함")
	_check(state.careerTitles.is_empty(), "CL-02 미리보기는 칭호를 지급하지 않음")
	print("[GOAL] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _state() -> Dictionary:
	return {"time": {"slot": 0}, "unlocks": {"stage": 1}, "settings": {"guidanceSeen": []}, "lifetimeStats": {"activities": 0, "adventures": 0}, "careerTitles": {}, "meters": {"energy": 100.0, "stress": 0.0}}

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
