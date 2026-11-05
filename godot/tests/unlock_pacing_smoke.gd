extends SceneTree

# AC-UNLOCK-10: 성장 방향 8종이 84일 안에 7단계에 도달하고, 단계적 해금 뒤에도
# 112일 능력치 합이 단계적 해금 전(f67378a) 기준의 90% 이상인지 측정한다.
# 기준값은 docs/design/2026-11-progressive-unlock/design.md의 밸런스 표와 같다.
const SEED: int = 20261104
const BASELINE_DAY_112: Dictionary = {
	"balanced": 2137.8,
	"martial": 2440.5,
	"scholar": 2174.7,
	"artist": 2288.5,
	"leader": 2127.3,
	"care": 2388.1,
	"explorer": 2108.6,
	"prosperity": 1981.5,
}
const FLOOR_RATIO: float = 0.90

var _passes: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for preset: String in BASELINE_DAY_112.keys():
		_measure(preset)
	if _failures.is_empty():
		print("[UNLOCK-PACING] PASS checks=%d" % _passes)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[FAIL] %s" % failure)
	print("[UNLOCK-PACING] FAIL passed=%d failed=%d" % [_passes, _failures.size()])
	quit(1)


func _measure(preset: String) -> void:
	var engine := GameEngine.new()
	engine.initialize(SEED)
	engine.set_policy(preset)
	var stage_seven_day: int = -1
	var activities_at_season_end: Array[int] = []
	for day: int in range(1, 113):
		engine.advance_slots(1)
		var state: Dictionary = engine.get_state()
		# 플레이어가 이벤트에 답하지 않으면 기본 선택이 적용되는 것과 같게 처리한다.
		for entry: Variant in (state.get("eventInbox", []) as Array).duplicate():
			engine.resolve_default_event(str((entry as Dictionary).get("instanceId", (entry as Dictionary).get("id", ""))))
		state = engine.get_state()
		if stage_seven_day < 0 and UnlockProgress.stage_of(state) >= 7:
			stage_seven_day = day
		if day % 28 == 0:
			activities_at_season_end.append(int((state.get("lifetimeStats", {}) as Dictionary).get("activities", 0)))
	var final_state: Dictionary = engine.get_state()
	var total: float = 0.0
	for value: Variant in (final_state.get("stats", {}) as Dictionary).values():
		total += float(value)
	var baseline: float = float(BASELINE_DAY_112[preset])
	var stalled: bool = false
	var previous: int = 0
	for count: int in activities_at_season_end:
		stalled = stalled or count <= previous
		previous = count
	print("[UNLOCK-PACING] %s stage7Day=%d day112Stats=%.1f baseline=%.1f ratio=%.3f activities=%s" % [preset, stage_seven_day, total, baseline, total / baseline, str(activities_at_season_end)])
	_check(stage_seven_day > 0 and stage_seven_day <= 84, "%s 84일 안에 7단계 도달(%d일)" % [preset, stage_seven_day])
	_check(total >= baseline * FLOOR_RATIO, "%s 112일 능력치 합 %.1f >= 기준 %.1f의 90%%" % [preset, total, baseline])
	_check(not stalled, "%s 시즌마다 활동 진행" % preset)
	_check(bool(engine.validate_state().get("ok", false)), "%s 상태 불변식" % preset)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
	else:
		_failures.append(label)
