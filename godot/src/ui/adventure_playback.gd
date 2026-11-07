extends RefCounted

# UI 전용 시계와 이미 확정된 결과의 장면 목록. 게임 엔진이나 난수를 호출하지 않는다.
var elapsed := 0.0
var sequence_id := ""
var _phases: Array[Dictionary] = []
var _duration := 0.0

func set_outcome(id: String, outcome: Dictionary) -> void:
	if sequence_id == id:
		return
	sequence_id = id
	elapsed = 0.0
	_phases.clear()
	_duration = 0.0
	var presentation: Variant = outcome.get("presentation", {})
	var nodes: Variant = (presentation as Dictionary).get("nodes", []) if presentation is Dictionary else []
	var raw_version: Variant = (presentation as Dictionary).get("version", 0) if presentation is Dictionary else 0
	var version := int(raw_version) if raw_version is int or raw_version is float else 0
	if not nodes is Array:
		nodes = []
	if version != 1:
		nodes = outcome.get("nodes", [])
		if not nodes is Array:
			nodes = []
	if nodes.size() > 3:
		nodes = []
	for raw_node: Variant in nodes:
		if not raw_node is Dictionary:
			continue
		var node: Dictionary = (raw_node as Dictionary).duplicate(true)
		if not _valid_node(node):
			continue
		var type := str(node.get("type", "event"))
		var raw_turns: Variant = node.get("turns", [])
		var turns: Array = raw_turns if raw_turns is Array and version == 1 else []
		turns = _valid_turns(turns)
		node.erase("turns")
		node["has_turns"] = not turns.is_empty()
		node["actor"] = ""
		if turns.is_empty():
			_add(node, 1.1)
		else:
			var ready := node.duplicate(true)
			ready["playerHp"] = node.get("initialPlayerHp", 0.0)
			ready["enemyHp"] = node.get("enemyMaxHp", 0.0)
			_add(ready, 0.3)
			var shown: Array = turns
			if turns.size() > 6:
				shown = [turns[0], turns[1], _summarize(turns.slice(2, turns.size() - 2)), turns[-2], turns[-1]]
			for raw_hit: Variant in shown:
				if not raw_hit is Dictionary:
					continue
				var hit: Dictionary = node.duplicate(true)
				hit.merge(raw_hit as Dictionary, true)
				_add(hit, 0.6 if str(hit.get("actor", "")) == "exchange" else 0.8)
			var end := node.duplicate(true)
			end["actor"] = "victory" if bool(node.get("won", false)) else "retreat"
			end["playerHp"] = node.get("remainingHp", 0.0)
			end["enemyHp"] = (turns.back() as Dictionary).get("enemyHp", 0.0) if turns.back() is Dictionary else 0.0
			_add(end, 0.9)
		if not bool(node.get("won", true)):
			break
	var summary: Dictionary = _phases.back().duplicate(true) if not _phases.is_empty() else {}
	summary.merge({"type": "result", "finished": true, "won": bool(outcome.get("won", false)), "has_turns": false}, true)
	_add(summary, 0.8)

func advance(delta: float, running: bool, reduced_motion: bool) -> void:
	if running and not reduced_motion:
		elapsed = minf(_duration, elapsed + maxf(0.0, delta))

func skip() -> void:
	elapsed = _duration

func current() -> Dictionary:
	if _phases.is_empty():
		return {"type": "result", "finished": true, "has_turns": false}
	for phase: Dictionary in _phases:
		if elapsed < float(phase["end"]):
			return phase
	return _phases.back()

func duration() -> float:
	return _duration

func _add(value: Dictionary, seconds: float) -> void:
	var phase := value.duplicate(true)
	phase["start"] = _duration
	_duration += seconds
	phase["end"] = _duration
	_phases.append(phase)

func _summarize(turns: Array) -> Dictionary:
	var trainee_damage := 0
	var enemy_damage := 0
	var last: Dictionary = {}
	for raw: Variant in turns:
		if not raw is Dictionary:
			continue
		last = raw as Dictionary
		if str(last.get("actor", "")) == "trainee":
			trainee_damage += int(last.get("damage", 0))
		else:
			enemy_damage += int(last.get("damage", 0))
	return {"actor": "exchange", "traineeDamage": trainee_damage, "enemyDamage": enemy_damage, "hitCount": turns.size(), "playerHp": last.get("playerHp", 0.0), "enemyHp": last.get("enemyHp", 0.0)}

func _valid_turns(turns: Array) -> Array:
	if turns.size() > 60:
		return []
	for raw: Variant in turns:
		if not raw is Dictionary:
			return []
		var hit: Dictionary = raw as Dictionary
		if str(hit.get("actor", "")) not in ["trainee", "enemy"]:
			return []
		for key: String in ["damage", "playerHp", "enemyHp"]:
			var number: Variant = hit.get(key)
			if not (number is int or number is float) or not is_finite(float(number)) or float(number) < 0.0:
				return []
		if float(hit["damage"]) < 1.0:
			return []
	return turns

func _valid_node(node: Dictionary) -> bool:
	if str(node.get("type", "")) not in ["exploration", "event", "encounter", "boss"]:
		return false
	for key: String in ["node", "initialPlayerHp", "enemyMaxHp", "remainingHp"]:
		if not node.has(key):
			continue
		var value: Variant = node[key]
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0:
			return false
	var effect: Variant = node.get("effect", {})
	if effect is Dictionary and (effect as Dictionary).has("hp"):
		var value: Variant = (effect as Dictionary)["hp"]
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	return true
