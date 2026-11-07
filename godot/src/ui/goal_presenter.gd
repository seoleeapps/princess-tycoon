extends RefCounted

# 목표 표시만 계산하며 게임 상태, 난수와 보상을 바꾸지 않는다.
static func describe(state: Dictionary, unlock_status: Dictionary, careers: Array = [], context: Dictionary = {}) -> Dictionary:
	var slot := maxi(0, int((state.get("time", {}) as Dictionary).get("slot", 0)))
	var season_days := maxi(1, int(context.get("season_days", 28)))
	var stage := int((state.get("unlocks", {}) as Dictionary).get("stage", 1))
	var result := {
		"headline": "첫 목표 · 시즌 심사 받기",
		"detail": "수련생은 자동으로 활동해요. 성장 방향을 정해 진로 칭호를 모아요.",
		"progress": clampf(float(slot) / season_days, 0.0, 1.0),
		"progress_label": "심사까지 %d일 · 게임 속 수련 %d/%d일" % [season_days - slot % season_days, mini(slot, season_days), season_days],
		"next_title": "수련생의 활동 살펴보기",
		"next_detail": "활동은 자동으로 진행돼요.",
		"action": "activity",
		"action_label": "활동 살펴보기",
	}
	if slot >= season_days:
		result["progress"] = float(slot % season_days) / season_days
		result["progress_label"] = "다음 심사까지 %d일" % (season_days - slot % season_days)
		result["headline"] = "진로 칭호 모으기"
		if not careers.is_empty() and careers[0] is Dictionary:
			var target: Dictionary = careers[0] as Dictionary
			var stars := maxi(0, int(target.get("stars", 0)))
			result["headline"] = ("다음 별 · " if stars > 0 else "다음 칭호 · ") + str(target.get("name", "진로 칭호"))
			result["progress"] = clampf(float(target.get("progress", 0.0)), 0.0, 1.0)
			var missing: Array = target.get("missing", []) as Array
			result["detail"] = "조건 완료 · 다음 심사에서 확인해요." if missing.is_empty() else "준비할 것 · " + str(missing[0])
			result["progress_label"] = "조건 %d%% · 다음 심사까지 %d일" % [int(float(result["progress"]) * 100), season_days - slot % season_days]
	if bool(state.get("forceRest", false)):
		result["next_title"] = "부상 회복하기"
		result["next_detail"] = "부상을 회복할 때까지 자동으로 휴식해요. 회복 뒤 다시 원정할 수 있어요."
		result["action_label"] = "회복 활동 확인"
		return result
	var settings: Dictionary = state.get("settings", {}) as Dictionary
	var seen: Array = settings.get("guidanceSeen", []) as Array
	if stage >= 3 and settings.has("guidanceSeen") and not seen.has("first_direction"):
		result["next_title"] = "성장 방향 고르기"
		result["next_detail"] = "고른 방향은 다음 활동부터 반영돼요."
		result["action"] = "plan"
		result["action_label"] = "성장 방향 선택"
		return result
	var lifetime: Dictionary = state.get("lifetimeStats", {}) as Dictionary
	if stage >= 6 and int(lifetime.get("adventures", 0)) == 0:
		result["next_title"] = "첫 원정에 도전하기"
		if bool(state.get("forceRest", false)):
			result["next_detail"] = "지금은 부상 회복을 위한 휴식이 먼저예요."
		elif bool(context.get("forest_ready", false)):
			result["next_detail"] = "은잎 숲의 탐색, 조우, 보스에 도전해요."
			result["action"] = "world"
			result["action_label"] = "첫 원정 준비"
		else:
			result["next_detail"] = str(context.get("forest_lock_reason", "활동으로 원정을 준비해요."))
		return result
	var next: Dictionary = unlock_status.get("next", {}) as Dictionary
	if not next.is_empty():
		var remaining: Dictionary = next.get("remaining", {}) as Dictionary
		result["next_title"] = str(next.get("label", "다음 기능")) + " 열기"
		if remaining.has("activities"):
			var needed := maxi(0, int(remaining["activities"]))
			result["next_detail"] = "활동 %d회 더 마치면 열려요." % needed
		elif remaining.has("slot"):
			result["next_detail"] = "%d일 뒤에 열려요." % maxi(0, int(remaining["slot"]))
		elif remaining.has("seasonReviews"):
			var days := maxi(0, int(remaining["seasonReviews"])) * season_days - slot % season_days
			result["next_detail"] = "%d일 뒤 시즌 심사를 마치면 열려요." % days
	elif stage >= 5:
		result["next_title"] = "진로 조건에 맞춰 성장시키기"
		result["next_detail"] = "기록에서 가까운 칭호와 준비할 것을 확인해요."
		result["action"] = "record"
		result["action_label"] = "진로 목표 확인"
	return result
