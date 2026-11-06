extends RefCounted

# 저장·게임 RNG와 무관한 홈 장면 재생 상태. MainScreen이 소유하여 페이지 재생성을 견딘다.
const ASSET_DIR := "res://assets/pixel_animations/"
const FRAME_SIZE := 64
const FRAME_COUNT := 8
const ACTIVITY_FPS := 6.0
const ENVIRONMENT_FPS := 4.0

static var _textures: Dictionary = {}

var activity_clip := ""
var environment_clip := ""
var activity_time := 0.0
var environment_time := 0.0
var scene_time := 0.0
var running := false
var reduced_motion := false
var _activity_key := ""


func set_activity_context(activity: Dictionary, value: bool) -> void:
	var next_clip := _clip_for(activity)
	var key := "%s:%s" % [str(activity.get("id", "")), next_clip]
	if _activity_key != key:
		activity_time = 0.0
		_activity_key = key
	activity_clip = next_clip
	running = value


func set_environment(value: String) -> void:
	var next := ""
	if value in ["academy", "library"]:
		next = "candle"
	elif value in ["city", "forest"]:
		next = "leaves"
	environment_clip = next


func advance(delta: float) -> void:
	if not running or reduced_motion:
		return
	activity_time = fmod(activity_time + delta, FRAME_COUNT / ACTIVITY_FPS)
	environment_time = fmod(environment_time + delta, FRAME_COUNT / ENVIRONMENT_FPS)
	scene_time = fmod(scene_time + delta, 1.0)


func frame(ambient: bool = false) -> int:
	if reduced_motion:
		return 0
	return int(floorf((environment_time if ambient else activity_time) * (ENVIRONMENT_FPS if ambient else ACTIVITY_FPS))) % FRAME_COUNT


func idle_frame() -> int:
	return 0 if reduced_motion else int(scene_time / 0.5)


static func texture_for(clip: String, reference: bool) -> Texture2D:
	if clip.is_empty():
		return null
	var path := ASSET_DIR + ("references/" if reference else "") + clip + ".png"
	var key := "%s:%s" % [path, reference]
	if _textures.has(key):
		return _textures[key] as Texture2D
	var texture: Texture2D
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
		var expected := Vector2(FRAME_SIZE if reference else FRAME_SIZE * FRAME_COUNT, FRAME_SIZE)
		if texture != null and texture.get_size() != expected:
			texture = null
	_textures[key] = texture
	return texture


static func _clip_for(activity: Dictionary) -> String:
	match str(activity.get("kind", "")):
		"education": return "magic" if (activity.get("tags", []) as Array).has("magic") else "book"
		"job": return "ledger"
		"rest": return "tea"
		"adventure": return "compass"
		"challenge", "exam", "sport", "contest", "league": return "flag"
	return ""
