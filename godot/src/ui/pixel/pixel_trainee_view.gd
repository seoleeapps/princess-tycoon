extends Control

# 홈 장면: PixelLab 수련생과 활동별 배경, 말풍선, 장비 강화 반짝임.
# 아트 1px = 논리 2px. 몸 모션은 6fps이며 모션 줄이기에서는 참조 프레임을 쓴다.

const PixelTheme = preload("res://src/ui/pixel/pixel_theme.gd")
const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const TraineeCompositor = preload("res://src/ui/pixel/painted_trainee_compositor.gd")
const Catalog = preload("res://src/ui/pixel/painted_catalog.gd")
const PixelAnimationPlayer = preload("res://src/ui/pixel/pixel_animation_player.gd")

const ICON_DIR := "res://assets/pixel/icons/"
const ENVIRONMENTS := ["academy", "library", "city", "forest", "arena", "cave", "ruins", "volcano", "rift"]
const SCALE := 2.0
const SLOTS := ["outfit", "weapon", "armor", "accessory"]

static var _shared_compositor: RefCounted

var profile := "balanced"
var environment := "academy"
var reduced_motion := false
var equipment: Dictionary = {}
var activity_icon := "activity"
var progress := 0.0

var _trainee_texture: ImageTexture
var _trainee_source: Image
var _frame := 0
var animation_player: RefCounted = PixelAnimationPlayer.new()
var _animation_frames := Vector2i(-1, -1)
var _animation_clips := ""
var _body_clip := "idle"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_refresh_trainee()
	set_process(true)


func set_profile(value: String) -> void:
	profile = value
	_refresh_trainee()


func set_environment(value: String) -> void:
	environment = value if ENVIRONMENTS.has(value) else "academy"
	animation_player.call("set_environment", environment)
	queue_redraw()


func set_equipment(value: Dictionary) -> void:
	equipment = value.duplicate(true)
	_refresh_trainee()


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	animation_player.set("reduced_motion", value)
	if reduced_motion:
		_frame = 8
	_refresh_trainee()


func set_animation_player(value: RefCounted) -> void:
	animation_player = value
	queue_redraw()


func set_activity_context(activity: Dictionary, running: bool) -> void:
	animation_player.call("set_activity_context", activity, running)
	var next_clip := "walk" if str(activity.get("kind", "")) == "adventure" else "idle"
	if next_clip != _body_clip:
		_body_clip = next_clip
		_refresh_trainee()
	queue_redraw()


func set_activity(icon_name: String, ratio: float) -> void:
	activity_icon = icon_name if ResourceLoader.exists(ICON_DIR + icon_name + ".png") else "activity"
	progress = clampf(ratio, 0.0, 1.0)
	queue_redraw()


# 매 프레임 불려도 게이지가 2px 단위로 바뀔 때만 다시 그린다.
func set_progress(ratio: float) -> void:
	var next := clampf(ratio, 0.0, 1.0)
	var changed := _progress_step(next) != _progress_step(progress)
	progress = next
	if changed:
		queue_redraw()


func _progress_step(value: float) -> int:
	return int(floorf(32.0 * value / SCALE))


func current_frame() -> int:
	return 0 if _frame == 8 else _frame


func trainee_image() -> Image:
	return _trainee_source


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var frames := Vector2i(animation_player.call("frame", false), animation_player.call("frame", true))
	var idle := 8 if reduced_motion else int(floorf(float(animation_player.get("activity_time")) * 6.0)) % 8
	var clips := "%s:%s" % [animation_player.get("activity_clip"), animation_player.get("environment_clip")]
	if frames != _animation_frames or idle != _frame or clips != _animation_clips:
		_animation_frames = frames
		_animation_clips = clips
		_frame = idle
		_refresh_trainee()


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var background := Catalog.background(environment)
	if background == null:
		return
	var bg_size := background.get_size() * SCALE
	var bg_origin := _even(Vector2((size.x - bg_size.x) * 0.5, size.y - bg_size.y))
	draw_texture_rect(background, Rect2(bg_origin, bg_size), false)
	# 환경은 왼쪽 바닥, 도구는 오른쪽 바닥에 둔다. 캔버스 기준점은 (32, 52) 아트픽셀.
	_draw_clip(str(animation_player.get("environment_clip")), true, bg_origin + Vector2(42, 166) * SCALE)
	if _trainee_texture == null:
		return
	var body_size := Vector2(_trainee_texture.get_size())
	var feet_y := size.y - 28.0
	var body_origin := _even(Vector2(size.x * 0.5 - 88.0 * SCALE, feet_y - 137.0 * SCALE))
	_draw_sparkles(body_origin, body_size)
	draw_texture(_trainee_texture, body_origin)
	_draw_clip(str(animation_player.get("activity_clip")), false, bg_origin + Vector2(144, 166) * SCALE)
	_draw_bubble(Vector2(size.x * 0.5 + 78.0, body_origin.y + 130.0))


func _draw_clip(clip: String, ambient: bool, anchor: Vector2) -> void:
	var texture: Texture2D = animation_player.call("texture_for", clip, reduced_motion)
	if texture == null:
		return
	var index := 0 if reduced_motion else int(animation_player.call("frame", ambient))
	var source := Rect2(Vector2(index * 64, 0), Vector2(64, 64))
	var destination := Rect2(_even(anchor - Vector2(32, 52) * SCALE), Vector2(128, 128))
	draw_texture_rect_region(texture, destination, source)


func _draw_bubble(anchor: Vector2) -> void:
	var bubble := PixelTheme.doubled_texture(ICON_DIR + "bubble.png")
	var bubble_size := bubble.get_size()
	var origin := _even(Vector2(anchor.x - bubble_size.x * 0.5, anchor.y - bubble_size.y - 12.0))
	draw_texture(bubble, origin)
	var icon := PixelTheme.doubled_texture(ICON_DIR + activity_icon + ".png")
	draw_texture(icon, _even(origin + Vector2((bubble_size.x - icon.get_size().x) * 0.5, 4.0)))
	# 어두운 벽 위에서도 보이도록 밝은 바탕 칸에 진행을 채운다.
	var bar := Rect2(_even(Vector2(origin.x - 2.0, origin.y + bubble_size.y + 2.0)), Vector2(bubble_size.x + 4.0, 10.0))
	draw_rect(bar, PixelTokens.STRIP_DARK)
	draw_rect(Rect2(bar.position + Vector2(2, 2), bar.size - Vector2(4, 4)), PixelTokens.SECONDARY)
	var fill_width := floorf((bar.size.x - 4.0) * progress / SCALE) * SCALE
	draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2(fill_width, 6.0)), PixelTokens.GAUGE["magic"])


# 장비 강화 레벨이 높을수록 몸 주변 반짝임이 늘어난다. 위치는 visualSeed로 고정한다.
func _draw_sparkles(body_origin: Vector2, body_size: Vector2) -> void:
	var level := _max_enhancement_level()
	var count := mini(10, level / 3)
	if count <= 0:
		return
	var seed_value := int(equipment.get("visualSeed", 1))
	var colors := [PixelTokens.GOLD, PixelTokens.GAUGE["magic"], PixelTokens.GAUGE["stat"], Color("#fff4c8")]
	for index in count:
		var hashed := absi(hash("%d:%d" % [seed_value, index]))
		var x := body_origin.x - 12.0 + float(hashed % int(body_size.x + 24.0))
		var y := body_origin.y + float((hashed / 97) % int(body_size.y * 0.8))
		if not reduced_motion and (index + _frame) % 3 == 0:
			continue
		draw_rect(Rect2(_even(Vector2(x, y)), Vector2(SCALE, SCALE)), colors[hashed % colors.size()])


func _max_enhancement_level() -> int:
	var levels: Dictionary = equipment.get("enhancementLevels", {}) as Dictionary
	var result := 0
	for slot: String in SLOTS:
		result = maxi(result, int(levels.get(slot, 0)))
	return result


func _refresh_trainee() -> void:
	if _shared_compositor == null:
		_shared_compositor = TraineeCompositor.new()
	var image: Image = _shared_compositor.call("compose", profile, equipment, _body_clip, 8 if reduced_motion else _frame)
	if image != null:
		var doubled := image.duplicate() as Image
		doubled.resize(image.get_width() * int(SCALE), image.get_height() * int(SCALE), Image.INTERPOLATE_NEAREST)
		_trainee_texture = ImageTexture.create_from_image(doubled)
		_trainee_source = image
	queue_redraw()


func _even(point: Vector2) -> Vector2:
	return Vector2(floorf(point.x / SCALE) * SCALE, floorf(point.y / SCALE) * SCALE)
