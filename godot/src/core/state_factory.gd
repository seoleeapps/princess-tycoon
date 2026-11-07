class_name StateFactory
extends RefCounted

const SCHEMA_VERSION: int = 2
const STAT_KEYS: Array[String] = [
	"stamina", "strength", "intelligence", "refinement", "sensitivity",
	"style", "discipline", "morals", "faith", "combat", "magic",
	"etiquette", "communication", "art", "cooking", "housework",
	"nursing", "dance",
]


static func create(seed_value: int = 1, player_name: String = "수련생", config_data: Dictionary = {}) -> Dictionary:
	var stats: Dictionary = {}
	var configured_stats: Dictionary = config_data.get("startStats", {}) as Dictionary
	for stat_key: String in STAT_KEYS:
		stats[stat_key] = maxf(0.0, float(configured_stats.get(stat_key, 0.0)))
	var start_gold: Dictionary = BigValue.from_number(config_data.get("startGold", 3000))
	var configured_relations: Dictionary = config_data.get("startRelations", {}) as Dictionary
	var policy: Dictionary = GrowthPolicy.create(
		"balanced",
		{},
		[],
		config_data.get("defaultReserveGold", 300),
		float(config_data.get("defaultMaxStress", 72.0)),
		float(config_data.get("defaultRiskTolerance", 0.35))
	)
	return {
		"schemaVersion": SCHEMA_VERSION,
		"seed": seed_value,
		"rngCounter": 0,
		"playerName": player_name,
		"traineeName": player_name,
		"lastSimulatedAt": 0,
		"time": {"slot": 0, "season": 1, "year": 1},
		"stats": stats,
		"meters": {
			"energy": clampf(float(config_data.get("startEnergy", 100.0)), 0.0, 100.0),
			"stress": clampf(float(config_data.get("startStress", 0.0)), 0.0, 100.0),
			"reputation": maxf(0.0, float(config_data.get("startReputation", 50.0))),
			"integrityViolations": 0,
		},
		"bigValues": {
			"gold": BigValue.clone(start_gold),
			"lifetimeGold": BigValue.clone(start_gold),
			"renown": BigValue.zero(),
			"lifetimeRenown": BigValue.zero(),
		},
		"growthPolicy": policy,
		"activityQueue": [],
		"activeTask": null,
		"mastery": {},
		"recentActivities": [],
		"inventory": [],
		"equipment": {"outfit": null, "weapon": null, "armor": null, "accessory": null},
		"relations": {
			"guardian": clampf(float(configured_relations.get("guardian", 100.0)), 0.0, 1000.0),
			"steward": clampf(float(configured_relations.get("steward", 100.0)), 0.0, 1000.0),
			"rival": clampf(float(configured_relations.get("rival", 0.0)), 0.0, 1000.0),
			"citizens": clampf(float(configured_relations.get("citizens", 50.0)), 0.0, 1000.0),
		},
		"worldTier": 1,
		"challengeLeague": {
			"leagueTier": 1,
			"bestScore": 0.0,
			"lastScore": 0.0,
			"lastOpponentScore": 0.0,
			"lastOpponentId": "",
			"seasonIndex": 1,
			"seasonWins": 0,
			"seasonLosses": 0,
		},
		"challengeRecords": {},
		"regionProgress": {},
		"seasonHistory": [],
		"generatedContent": {"contracts": [], "rivals": [], "region": {}, "generatedFor": {}, "pinnedContractId": ""},
		"generatedHistory": {"recentContractTemplates": []},
		"eventInbox": [],
		"eventHistory": {},
		"eventCooldowns": {},
		"careerTitles": {},
		"lifetimeStats": {
			"activities": 0,
			"challengeWins": 0,
			"contracts": 0,
			"adventures": 0,
		},
		"unlocks": {"stage": 1, "announced": 1, "tipsSeen": []},
		"seasonCounters": {"challengeWins": 0, "completedContracts": 0},
		"recentGrowthVectors": [],
		"flags": {},
		"warnings": [],
		"forceRest": false,
		"lastPlannerDecision": {},
		"lastResult": {},
		"settings": {"autoRun": true, "reducedMotion": false, "sound": true, "highContrast": false, "guidanceSeen": []},
	}


static func create_v2(seed_value: int = 1, player_name: String = "수련생", config_data: Dictionary = {}) -> Dictionary:
	return create(seed_value, player_name, config_data)


static func ensure_v2_shape(input_state: Dictionary) -> Dictionary:
	var defaults: Dictionary = create(
		int(input_state.get("seed", 1)),
		str(input_state.get("playerName", input_state.get("name", "수련생")))
	)
	var merged: Dictionary = _deep_fill(input_state.duplicate(true), defaults)
	# 이 필드가 없던 기존 기록은 첫 실행 안내를 강제로 다시 받지 않는다.
	var previous_settings: Variant = input_state.get("settings", {})
	if not previous_settings is Dictionary or not (previous_settings as Dictionary).get("guidanceSeen") is Array:
		(merged["settings"] as Dictionary)["guidanceSeen"] = ["intro", "first_direction"]
	# 해금 단계가 없던 저장은 기본값(1단계)을 채우지 않는다. 엔진이 진행값으로 단계를 계산한다.
	if input_state.get("unlocks") is not Dictionary:
		merged.erase("unlocks")
	merged["schemaVersion"] = SCHEMA_VERSION
	merged["growthPolicy"] = GrowthPolicy.sanitize(merged.get("growthPolicy", {}) as Dictionary)
	var big_values: Dictionary = merged["bigValues"] as Dictionary
	for key: String in ["gold", "lifetimeGold", "renown", "lifetimeRenown"]:
		big_values[key] = BigValue.from_number(big_values.get(key, BigValue.zero()))
	var meters: Dictionary = merged["meters"] as Dictionary
	meters["energy"] = clampf(float(meters.get("energy", 100.0)), 0.0, 100.0)
	meters["stress"] = clampf(float(meters.get("stress", 0.0)), 0.0, 100.0)
	meters["reputation"] = maxf(0.0, float(meters.get("reputation", 50.0)))
	return merged


static func _deep_fill(target: Dictionary, defaults: Dictionary) -> Dictionary:
	for key: Variant in defaults.keys():
		if not target.has(key) or target[key] == null and defaults[key] != null:
			target[key] = (defaults[key] as Dictionary).duplicate(true) if defaults[key] is Dictionary else (defaults[key] as Array).duplicate(true) if defaults[key] is Array else defaults[key]
		elif target[key] is Dictionary and defaults[key] is Dictionary:
			target[key] = _deep_fill(target[key] as Dictionary, defaults[key] as Dictionary)
	return target
