extends Control

# 홈 장면: 활동별 배경, 도트 페이퍼돌 수련생, 머리 위 활동 말풍선과 진행 게이지, 장비 강화 반짝임.
# 아트 1px = 논리 2px로만 그린다. 대기 모션은 0.5초 간격 2프레임(1 아트픽셀 오르내림)이고 모션 줄이기에서 멈춘다.

const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const TraineeCompositor = preload("res://src/ui/pixel/trainee_compositor.gd")

const SPRITE := "res://assets/pixel/sprites/trainee.json"
const SCENE_DIR := "res://assets/pixel/scenes/"
const ICON_DIR := "res://assets/pixel/icons/"
const ENVIRONMENTS := ["academy", "library", "city", "forest", "arena"]
const SCALE := 2.0
const FRAME_SECONDS := 0.5
const SLOTS := ["outfit", "weapon", "armor", "accessory"]

static var _shared_compositor: RefCounted
static var _doubled := {}

var profile := "balanced"
var environment := "academy"
var reduced_motion := false
var equipment: Dictionary = {}
var activity_icon := "activity"
var progress := 0.0
var expression := "focus"

var _trainee_texture: ImageTexture
var _trainee_source: Image
var _frame := 0
var _elapsed := 0.0


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
	queue_redraw()


func set_equipment(value: Dictionary) -> void:
	equipment = value.duplicate(true)
	_refresh_trainee()


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if reduced_motion:
		_frame = 0
	queue_redraw()


func set_activity(icon_name: String, ratio: float) -> void:
	activity_icon = icon_name if ResourceLoader.exists(ICON_DIR + icon_name + ".png") else "activity"
	progress = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func current_frame() -> int:
	return _frame


func trainee_image() -> Image:
	return _trainee_source


func _process(delta: float) -> void:
	if reduced_motion:
		return
	_elapsed += delta
	if _elapsed >= FRAME_SECONDS:
		_elapsed = fmod(_elapsed, FRAME_SECONDS)
		_frame = 1 - _frame
		queue_redraw()


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var background := _doubled_texture(SCENE_DIR + environment + ".png")
	var bg_size := background.get_size()
	var bg_origin := _even(Vector2((size.x - bg_size.x) * 0.5, size.y - bg_size.y))
	draw_texture(background, bg_origin)
	if _trainee_texture == null:
		return
	var body_size := Vector2(_trainee_texture.get_size())
	var feet_y := bg_origin.y + 160.0 * SCALE
	var bob := -SCALE if _frame == 1 else 0.0
	var body_origin := _even(Vector2((size.x - body_size.x) * 0.5, feet_y - body_size.y + bob))
	_draw_sparkles(body_origin, body_size)
	draw_texture(_trainee_texture, body_origin)
	_draw_bubble(Vector2(body_origin.x + body_size.x * 0.5, body_origin.y - 4.0))


func _draw_bubble(anchor: Vector2) -> void:
	var bubble := _doubled_texture(ICON_DIR + "bubble.png")
	var bubble_size := bubble.get_size()
	var origin := _even(Vector2(anchor.x - bubble_size.x * 0.5, anchor.y - bubble_size.y - 12.0))
	draw_texture(bubble, origin)
	var icon := _doubled_texture(ICON_DIR + activity_icon + ".png")
	draw_texture(icon, _even(origin + Vector2((bubble_size.x - icon.get_size().x) * 0.5, 4.0)))
	var bar := Rect2(_even(Vector2(origin.x - 2.0, origin.y + bubble_size.y + 2.0)), Vector2(bubble_size.x + 4.0, 8.0))
	draw_rect(bar, PixelTokens.STRIP_DARK)
	var fill_width := floorf((bar.size.x - 4.0) * progress / SCALE) * SCALE
	draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2(fill_width, 4.0)), PixelTokens.GAUGE["magic"])


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
		_shared_compositor.call("load_sprite", SPRITE)
	var image: Image = _shared_compositor.call("compose", profile, equipment, expression)
	if image != null:
		var doubled := image.duplicate() as Image
		doubled.resize(image.get_width() * int(SCALE), image.get_height() * int(SCALE), Image.INTERPOLATE_NEAREST)
		_trainee_texture = ImageTexture.create_from_image(doubled)
		_trainee_source = image
	queue_redraw()


# 1배 도트를 nearest로 2배 키운 텍스처를 1:1로 그린다. 뷰포트 필터 설정과 무관하게 도트가 선명하다.
static func _doubled_texture(path: String) -> Texture2D:
	if _doubled.has(path):
		return _doubled[path]
	var image := (load(path) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() * int(SCALE), image.get_height() * int(SCALE), Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	_doubled[path] = texture
	return texture


func _even(point: Vector2) -> Vector2:
	return Vector2(floorf(point.x / SCALE) * SCALE, floorf(point.y / SCALE) * SCALE)
