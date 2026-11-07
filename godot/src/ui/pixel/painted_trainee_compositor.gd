extends RefCounted

const Catalog = preload("res://src/ui/pixel/painted_catalog.gd")
var _cache: Dictionary = {}

# 모든 아틀라스는 원본 크기다. 장비는 프레임마다 검수한 손·가슴·머리 기준점에 붙인다.
func compose(profile: String, equipment: Dictionary, clip: String = "idle", frame: int = 8) -> Image:
	var data := Catalog.data()
	var profiles: Array = data.get("profiles", [])
	var row := maxi(0, profiles.find(profile))
	var bodies: Dictionary = data.get("bodies", {})
	var outfit := str(equipment.get("outfit", "OUTFIT_PLAIN"))
	if not bodies.has(outfit):
		outfit = "OUTFIT_PLAIN"
	if not bodies.has(outfit):
		return null
	if clip not in ["idle", "walk", "attack"]:
		clip = "idle"
	frame = clampi(frame, 0, 8)
	var key := "%d:%s:%s:%d:%s:%s:%s" % [row, outfit, clip, frame, equipment.get("armor", ""), equipment.get("weapon", ""), equipment.get("accessory", "")]
	if _cache.has(key):
		return _cache[key]
	var spec: Dictionary = (bodies[outfit] as Dictionary).get(clip, {})
	var atlas := Catalog.image(str(spec.get("path", "")))
	if atlas == null:
		return null
	var result := Image.create(208, 160, false, Image.FORMAT_RGBA8)
	result.blend_rect(atlas, Rect2i(frame * 128, row * 128, 128, 128), Vector2i(24, 16))
	var anchors: Dictionary = (spec["anchors"] as Array)[frame]
	var gear: Dictionary = data.get("gear", {})
	for slot: String in ["armor", "accessory", "weapon"]:
		var id := str(equipment.get(slot, ""))
		if not gear.has(id):
			continue
		var source := Catalog.image(str((gear[id] as Dictionary).get("path", "")))
		if source == null:
			continue
		var point: Array = (anchors[slot] as Array).duplicate()
		if id == "ACC_JEWEL":
			point = [(anchors["armor"] as Array)[0] + 2, (anchors["armor"] as Array)[1] - 8]
		var at := Vector2i(24 + int(point[0]) - 64, 16 + int(point[1]) - 64)
		result.blend_rect(source, Rect2i(frame * 128, ["idle", "walk", "attack"].find(clip) * 128, 128, 128), at)
	if _cache.size() >= 24:
		_cache.erase(_cache.keys()[0])
	_cache[key] = result
	return result
