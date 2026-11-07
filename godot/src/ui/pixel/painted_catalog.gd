extends RefCounted

const ROOT := "res://assets/pixellab_v2/"
static var _data: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(ROOT + "catalog.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "catalog.json"))
		if parsed is Dictionary:
			_data = parsed
	return _data

static func texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _textures.has(path):
		if _textures.size() >= 24:
			_textures.erase(_textures.keys()[0])
		_textures[path] = load(ROOT + path) as Texture2D if ResourceLoader.exists(ROOT + path) else null
	return _textures[path] as Texture2D

static func image(path: String) -> Image:
	if not _images.has(path):
		var source := texture(path)
		if source == null:
			return null
		if _images.size() >= 8:
			_images.erase(_images.keys()[0])
		_images[path] = source.get_image()
	return _images[path] as Image

static func background(environment: String) -> Texture2D:
	return texture(str((data().get("backgrounds", {}) as Dictionary).get(environment, "")))

static func environment_for(activity_id: String) -> String:
	return str({"ADV_FOREST": "forest", "ADV_CAVE": "cave", "ADV_RUINS": "ruins", "ADV_VOLCANO": "volcano", "ADV_RIFT": "rift"}.get(activity_id, "forest"))
