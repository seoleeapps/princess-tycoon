extends SceneTree

const FIXTURE := "res://tests/fixtures/adventure_baseline.json"
var checks := 0
var failed := 0

func _initialize() -> void:
	var baseline_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):
			baseline_path = arg.trim_prefix("--baseline=")
	var expected: Dictionary = {}
	if baseline_path.is_empty():
		expected = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	var records := {}
	var cases: Array[Dictionary] = []
	for activity_id in ["ADV_FOREST", "ADV_CAVE", "ADV_RUINS", "ADV_VOLCANO", "ADV_RIFT"]:
		cases.append({"id": activity_id, "seed": 915, "strong": true})
	for seed_value in range(1, 13):
		cases.append({"id": "ADV_FOREST", "seed": seed_value, "strong": false})
	for spec: Dictionary in cases:
		var engine := GameEngine.new()
		var initial := StateFactory.create(int(spec.seed))
		for key: String in initial.stats:
			initial.stats[key] = 700.0 if bool(spec.strong) else 0.0
		initial.stats.stamina = 700.0 if bool(spec.strong) else 70.0
		initial.unlocks = {"stage": 7, "announced": 7, "tipsSeen": []}
		initial.worldTier = 5 if bool(spec.strong) else 1
		initial.growthPolicy.riskTolerance = 1.0
		initial.growthPolicy.reserveGold = BigValue.zero()
		engine.initialize_from_state(initial)
		var result := engine.run_activity(str(spec.id), 1_800_000_000)
		var state := engine.get_state()
		var outcome: Dictionary = (result.get("result", {}) as Dictionary).get("outcome", {}) as Dictionary
		var key := "%s_%d_%s" % [spec.id, spec.seed, str(spec.strong)]
		records[key] = {"hash": JSON.stringify(_without_visual(state)).sha256_text(), "rngCounter": state.rngCounter, "won": outcome.get("won"), "ok": result.get("ok")}
		if baseline_path.is_empty():
			var old_record: Dictionary = expected.get(key, {}) as Dictionary
			_check(str(records[key].hash) == str(old_record.get("hash", "")) and int(records[key].rngCounter) == int(old_record.get("rngCounter", -1)) and bool(records[key].won) == bool(old_record.get("won", false)) and bool(records[key].ok) == bool(old_record.get("ok", false)), "AD-02 기존 상태·보상·난수 일치 " + key)
			_check(bool(result.get("ok", false)), "AD-01 원정 실행 " + key)
			var trace: Dictionary = outcome.get("presentation", {}) as Dictionary
			_check(int(trace.get("version", 0)) == 1, "AD-01 실제 판정의 장면 기록 " + key)
			for node: Dictionary in trace.get("nodes", []):
				var previous_player := float(node.get("initialPlayerHp", trace.get("maxPlayerHp", 0)))
				var previous_enemy := float(node.get("enemyMaxHp", 0))
				for hit: Dictionary in node.get("turns", []):
					var damage := float(hit.get("damage", 0))
					if str(hit.actor) == "trainee":
						previous_enemy = maxf(0.0, previous_enemy - damage)
					else:
						previous_player = maxf(0.0, previous_player - damage)
					_check(damage >= 1 and is_equal_approx(previous_enemy, float(hit.enemyHp)) and is_equal_approx(previous_player, float(hit.playerHp)), "AD-02 표시 HP와 실제 적용 피해 일치")
	var simulation := GameEngine.new()
	simulation.initialize(90210)
	simulation.advance_slots(1000, 1_800_000_000)
	var simulated := simulation.get_state()
	records["slots1000"] = {"hash": JSON.stringify(_without_visual(simulated)).sha256_text(), "rngCounter": simulated.rngCounter}
	if baseline_path.is_empty():
		var old_simulation: Dictionary = expected.get("slots1000", {}) as Dictionary
		_check(str(records.slots1000.hash) == str(old_simulation.get("hash", "")) and int(records.slots1000.rngCounter) == int(old_simulation.get("rngCounter", -1)), "AD-02 1000 slots 기존 전체 게임 상태·난수 일치")
	else:
		var f := FileAccess.open(baseline_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(records, "\t") + "\n")
		print("baseline fixture cases=%d" % records.size())
	print("[ADVENTURE-TRACE] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _without_visual(value: Variant) -> Variant:
	if value is Dictionary:
		var clean := {}
		for key: Variant in (value as Dictionary).keys():
			if str(key) not in ["presentation", "guidanceSeen"]:
				clean[key] = _without_visual(value[key])
		return clean
	if value is Array:
		var clean: Array = []
		for item: Variant in value:
			clean.append(_without_visual(item))
		return clean
	return value

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
