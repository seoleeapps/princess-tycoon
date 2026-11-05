class_name UnlockProgress
extends RefCounted

# 단계적 해금 규칙(GDD §2.2, 계약 §4.1). 단계는 저장된 진행값으로만 판정하고 난수를 쓰지 않는다.
const ALLOWED_CONDITIONS: Array[String] = ["activities", "slot", "seasonReviews"]

var _stages: Array[Dictionary] = []
var _feature_stage: Dictionary = {}
var _slots_per_season: int = 28


func configure(unlock_data: Dictionary, slots_per_season: int) -> void:
	_stages.clear()
	_feature_stage.clear()
	_slots_per_season = maxi(1, slots_per_season)
	for raw_stage: Variant in unlock_data.get("stages", []) as Array:
		if raw_stage is not Dictionary:
			continue
		var entry: Dictionary = (raw_stage as Dictionary).duplicate(true)
		_stages.append(entry)
		for raw_feature: Variant in entry.get("features", []) as Array:
			_feature_stage[str(raw_feature)] = int(entry.get("stage", 1))


func max_stage() -> int:
	return _stages.size()


# 상태에 저장된 단계. 1단계 미만이나 최대 단계 초과는 범위 안으로 맞춘다.
static func stage_of(state: Dictionary) -> int:
	var unlocks: Variant = state.get("unlocks", {})
	if unlocks is not Dictionary:
		return 1
	return maxi(1, int((unlocks as Dictionary).get("stage", 1)))


func feature_stage(feature_id: String) -> int:
	return int(_feature_stage.get(feature_id, 1))


func is_feature_unlocked(state: Dictionary, feature_id: String) -> bool:
	return stage_of(state) >= feature_stage(feature_id)


func season_reviews(state: Dictionary) -> int:
	return int((state.get("time", {}) as Dictionary).get("slot", 0)) / _slots_per_season


# 진행값이 충족하는 가장 높은 단계. 앞 단계 조건이 모두 충족되어야 다음 단계로 넘어간다.
func computed_stage(state: Dictionary) -> int:
	var reached: int = 1
	for entry: Dictionary in _stages:
		if not _condition_met(state, entry.get("when", {}) as Dictionary):
			break
		reached = maxi(reached, int(entry.get("stage", 1)))
	return clampi(reached, 1, maxi(1, max_stage()))


# 단계를 진행값에 맞춰 올리고 이번에 새로 열린 단계를 돌려준다. 단계는 내려가지 않는다.
func refresh(state: Dictionary) -> Array[int]:
	var opened: Array[int] = []
	var unlocks: Dictionary = _ensure_unlocks(state)
	var current: int = int(unlocks.get("stage", 1))
	var target: int = computed_stage(state)
	for stage_number: int in range(current + 1, target + 1):
		opened.append(stage_number)
	if target > current:
		unlocks["stage"] = target
	return opened


# unlocks가 없는 기존 저장: 진행값으로 단계를 계산하고 알림과 안내는 이미 본 것으로 둔다.
func legacy_unlocks(state: Dictionary) -> Dictionary:
	var stage_number: int = computed_stage(state)
	return {"stage": stage_number, "announced": stage_number, "tipsSeen": all_tip_features()}


func sanitize(state: Dictionary) -> void:
	var unlocks: Dictionary = _ensure_unlocks(state)
	var stage_number: int = clampi(int(unlocks.get("stage", 1)), 1, maxi(1, max_stage()))
	unlocks["stage"] = stage_number
	unlocks["announced"] = clampi(int(unlocks.get("announced", 1)), 1, stage_number)
	var seen: Array = []
	for raw_feature: Variant in unlocks.get("tipsSeen", []) as Array if unlocks.get("tipsSeen", []) is Array else []:
		var feature_id: String = str(raw_feature)
		if not feature_id.is_empty() and not seen.has(feature_id):
			seen.append(feature_id)
	unlocks["tipsSeen"] = seen


func all_tip_features() -> Array:
	var features: Array = []
	for entry: Dictionary in _stages:
		for raw_feature: Variant in (entry.get("tips", {}) as Dictionary).keys():
			features.append(str(raw_feature))
	return features


func stage_entry(stage_number: int) -> Dictionary:
	for entry: Dictionary in _stages:
		if int(entry.get("stage", 0)) == stage_number:
			return entry.duplicate(true)
	return {}


func tip(feature_id: String) -> String:
	var entry: Dictionary = stage_entry(feature_stage(feature_id))
	return str((entry.get("tips", {}) as Dictionary).get(feature_id, ""))


# 화면이 쓰는 현재 단계와 다음 단계까지 남은 양.
func status(state: Dictionary) -> Dictionary:
	var unlocks: Dictionary = _ensure_unlocks(state)
	var stage_number: int = int(unlocks.get("stage", 1))
	var next: Dictionary = {}
	var next_entry: Dictionary = stage_entry(stage_number + 1)
	if not next_entry.is_empty():
		var when: Dictionary = next_entry.get("when", {}) as Dictionary
		var remaining: Dictionary = {}
		for key: String in ALLOWED_CONDITIONS:
			if when.has(key):
				remaining[key] = maxi(0, int(when[key]) - _metric(state, key))
		next = {
			"stage": stage_number + 1,
			"label": str(next_entry.get("label", "")),
			"features": (next_entry.get("features", []) as Array).duplicate(),
			"remaining": remaining,
		}
	return {
		"stage": stage_number,
		"maxStage": max_stage(),
		"announced": int(unlocks.get("announced", 1)),
		"tipsSeen": (unlocks.get("tipsSeen", []) as Array).duplicate(),
		"next": next,
	}


# 데이터 검증: 1부터 연속, 조건 키 허용, 조건 값 단조 증가, 기능 중복 없음.
static func validate(unlock_data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var raw_stages: Variant = unlock_data.get("stages", [])
	if raw_stages is not Array or (raw_stages as Array).is_empty():
		errors.append("unlocks.json stages는 비어 있지 않은 배열이어야 합니다.")
		return errors
	var seen_features: Array[String] = []
	var last_values: Dictionary = {}
	var expected_stage: int = 1
	for raw_stage: Variant in raw_stages as Array:
		if raw_stage is not Dictionary:
			errors.append("unlocks.json 단계 항목은 객체여야 합니다.")
			continue
		var entry: Dictionary = raw_stage as Dictionary
		if int(entry.get("stage", 0)) != expected_stage:
			errors.append("unlocks.json 단계 번호는 1부터 연속이어야 합니다: %s" % str(entry.get("stage", "")))
		expected_stage += 1
		var when: Variant = entry.get("when", {})
		if when is not Dictionary or (when as Dictionary).size() > 1:
			errors.append("unlocks.json %d단계 when은 조건 0~1개 객체여야 합니다." % int(entry.get("stage", 0)))
		else:
			for raw_key: Variant in (when as Dictionary).keys():
				var key: String = str(raw_key)
				if not ALLOWED_CONDITIONS.has(key):
					errors.append("unlocks.json 허용되지 않은 조건: %s" % key)
					continue
				var value: int = int((when as Dictionary)[raw_key])
				if value < int(last_values.get(key, 0)):
					errors.append("unlocks.json %s 조건은 단계 순서대로 늘어나야 합니다." % key)
				last_values[key] = value
		for raw_feature: Variant in entry.get("features", []) as Array:
			var feature_id: String = str(raw_feature)
			if seen_features.has(feature_id):
				errors.append("unlocks.json 기능이 두 단계에 있습니다: %s" % feature_id)
			seen_features.append(feature_id)
		for raw_tip: Variant in (entry.get("tips", {}) as Dictionary).keys():
			if not (entry.get("features", []) as Array).has(raw_tip):
				errors.append("unlocks.json 안내는 같은 단계 기능에만 둘 수 있습니다: %s" % str(raw_tip))
	return errors


func _condition_met(state: Dictionary, when: Dictionary) -> bool:
	for key: String in ALLOWED_CONDITIONS:
		if when.has(key) and _metric(state, key) < int(when[key]):
			return false
	return true


func _metric(state: Dictionary, key: String) -> int:
	match key:
		"activities":
			return int((state.get("lifetimeStats", {}) as Dictionary).get("activities", 0))
		"slot":
			return int((state.get("time", {}) as Dictionary).get("slot", 0))
		"seasonReviews":
			return season_reviews(state)
	return 0


func _ensure_unlocks(state: Dictionary) -> Dictionary:
	if state.get("unlocks") is not Dictionary:
		state["unlocks"] = {"stage": 1, "announced": 1, "tipsSeen": []}
	return state["unlocks"] as Dictionary
