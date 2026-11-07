extends Control

const Catalog = preload("res://src/ui/pixel/painted_catalog.gd")
const PaintedCompositor = preload("res://src/ui/pixel/painted_trainee_compositor.gd")
var playback: RefCounted
var outcome: Dictionary = {}
var profile := "balanced"
var equipment: Dictionary = {}
var reduced_motion := false
var _compositor := PaintedCompositor.new()
var _last_key := ""
var _hero: Texture2D
var _phase: Dictionary = {}
var _frame := 8

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true

func _process(_delta: float) -> void:
	if playback == null or not is_visible_in_tree():
		return
	_phase = playback.call("current")
	var raw_trace: Variant = outcome.get("presentation", {})
	var trace: Dictionary = raw_trace if raw_trace is Dictionary else {}
	var version: Variant = trace.get("version", 0)
	var legacy := not (version is int or version is float) or int(version) != 1
	var elapsed := float(playback.get("elapsed"))
	var local := clampf((elapsed - float(_phase.get("start", 0.0))) / maxf(0.01, float(_phase.get("end", 1.0)) - float(_phase.get("start", 0.0))), 0.0, 0.999)
	var actor := str(_phase.get("actor", ""))
	var clip := "walk" if str(_phase.get("type", "")) == "exploration" or actor == "retreat" else "idle"
	if actor == "trainee":
		clip = "attack"
	if legacy or bool(_phase.get("finished", false)):
		clip = "idle"
	_frame = 8 if reduced_motion or legacy or bool(_phase.get("finished", false)) else (int(local * 8.0) if actor in ["trainee", "enemy", "victory"] else int(elapsed * 6.0) % 8)
	var key := "%s:%d:%s" % [clip, _frame, JSON.stringify(_phase)]
	if key != _last_key:
		_last_key = key
		var image := _compositor.compose(profile, equipment, clip, _frame)
		_hero = ImageTexture.create_from_image(image) if image != null else null
		queue_redraw()

func _draw() -> void:
	var raw_trace: Variant = outcome.get("presentation", {})
	var trace: Dictionary = raw_trace if raw_trace is Dictionary else {} as Dictionary
	var environment := Catalog.environment_for(str(trace.get("activityId", outcome.get("activityId", "ADV_FOREST"))))
	var background := Catalog.background(environment)
	if background != null:
		var bg_size := background.get_size() * 2.0
		draw_texture_rect(background, Rect2(Vector2(floorf((size.x - bg_size.x) / 4.0) * 2.0, size.y - bg_size.y), bg_size), false)
	var ground := floorf((size.y - 18.0) / 2.0) * 2.0
	var hero_foot := floorf(size.x * 0.26 / 2.0) * 2.0
	var elapsed := float(playback.get("elapsed")) if playback != null else 0.0
	var local := clampf((elapsed - float(_phase.get("start", 0.0))) / maxf(0.01, float(_phase.get("end", 1.0)) - float(_phase.get("start", 0.0))), 0.0, 1.0)
	var actor := str(_phase.get("actor", ""))
	if not reduced_motion:
		if str(_phase.get("type", "")) == "exploration":
			hero_foot -= floorf((1.0 - local) * 6.0) * 2.0
		elif actor == "retreat":
			hero_foot -= floorf(local * 6.0) * 2.0
		if actor == "enemy" and _frame < 3:
			hero_foot -= 2.0
	if _hero != null:
		draw_texture_rect(_hero, Rect2(Vector2(hero_foot - 176.0, ground - 274.0), Vector2(416, 320)), false, Color(1.0, 0.72, 0.65) if actor == "enemy" and _frame < 3 and not reduced_motion else Color.WHITE)
	var enemy_id := str(_phase.get("enemyId", ""))
	var enemies: Dictionary = Catalog.data().get("enemies", {})
	if not enemies.has(enemy_id):
		return
	var clip := "defeat" if actor == "victory" else ("attack" if actor == "enemy" else "idle")
	var spec: Dictionary = (enemies[enemy_id] as Dictionary).get(clip, {})
	var enemy := Catalog.texture(str(spec.get("path", "")))
	if enemy != null:
		var x := floorf((size.x - 256.0 - 8.0) / 2.0) * 2.0
		# 전체 128px 캔버스와 바닥 기준을 보존하여 뿔·발·꼬리를 자르지 않는다.
		draw_texture_rect_region(enemy, Rect2(Vector2(x, ground - 242.0), Vector2(256, 256)), Rect2((7 if bool(_phase.get("finished", false)) and clip == "defeat" and not reduced_motion else _frame) * 128, 0, 128, 128))
