extends RefCounted

# 수련생 도트 페이퍼돌 합성기. scripts/pixel_art/generate.py가 쓴 sprites/trainee.json을 읽어
# 성장 분야 색 치환과 장비 레이어를 CPU에서 합성한다. 같은 입력은 캐시한 Image를 돌려준다.

const SLOTS := ["outfit", "armor", "weapon", "accessory"]

var _size := Vector2i.ZERO
var _keys: Dictionary = {}
var _recolor: Dictionary = {}
var _layers: Dictionary = {}
var _order: Array = []
var _defaults: Dictionary = {}
var _cache: Dictionary = {}


func load_sprite(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("Trainee sprite missing: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Trainee sprite is not valid JSON: %s" % path)
		return false
	var data: Dictionary = parsed
	var size_value: Array = data.get("size", [0, 0])
	_size = Vector2i(int(size_value[0]), int(size_value[1]))
	_keys.clear()
	for key: String in data.get("keys", {}):
		_keys[key] = Color(str(data["keys"][key]))
	_recolor.clear()
	for preset: String in data.get("recolor", {}):
		var mapping := {}
		for key: String in data["recolor"][preset]:
			mapping[key] = Color(str(data["recolor"][preset][key]))
		_recolor[preset] = mapping
	_layers = data.get("layers", {}) as Dictionary
	_order = data.get("order", []) as Array
	_defaults = data.get("defaults", {}) as Dictionary
	_cache.clear()
	return _size.x > 0 and not _layers.is_empty()


func size() -> Vector2i:
	return _size


func compose(profile: String, equipment: Dictionary, expression: String = "smile") -> Image:
	var preset := profile if _recolor.has(profile) else "balanced"
	var face := expression if _layers.has("face:" + expression) else str(_defaults.get("expression", "smile"))
	var picks := {}
	for slot: String in SLOTS:
		var item := str(equipment.get(slot, "")) if equipment.get(slot) != null else ""
		if slot == "outfit" and item.is_empty():
			item = str(_defaults.get("outfit", ""))
		picks[slot] = item
	var cache_key := "%s|%s|%s|%s|%s|%s" % [preset, face, picks["outfit"], picks["armor"], picks["weapon"], picks["accessory"]]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var palette := _keys.duplicate()
	var mapping: Dictionary = _recolor.get(preset, {})
	for key: String in mapping:
		palette[key] = mapping[key]
	var image := Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	for slot: String in _order:
		var layer_name := slot
		if slot == "face":
			layer_name = "face:" + face
		elif SLOTS.has(slot):
			if str(picks[slot]).is_empty():
				continue
			layer_name = "%s:%s" % [slot, picks[slot]]
		if not _layers.has(layer_name):
			continue
		var rows: Array = _layers[layer_name]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				var key := row[x]
				if key != ".":
					image.set_pixel(x, y, palette[key])
	_cache[cache_key] = image
	return image
