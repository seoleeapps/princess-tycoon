extends SceneTree

# Google Play 스크린샷(9:16)을 실제 게임 화면으로 렌더링한다. 휴대전화 1080×1920, 7인치 1215×2160, 10인치 1440×2560.
#   godot --path godot --script res://tests/store_screenshots.gd -- --out <폴더> [--size=1080x1920]
# 같은 seed로 엔진을 197일(8시즌째 첫날, 시험 전) 진행한 실제 상태를 쓰고, 격리 저장 경로와 고정 시계를 쓴다.
# 390×844 논리 화면을 기기처럼 비율을 지켜 키우고(canvas_items + keep), 남는 좌우는 게임의 어두운 나무색으로 채운다.

const LOGICAL := Vector2i(390, 844)
var SHOT := Vector2i(1080, 1920)
const SAVE := "user://qa_store_screenshots.json"
const MARGIN := Color("3a2414")

var _out := ""
var _vp: SubViewport
var _main: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if args[index] == "--out" and index + 1 < args.size():
			_out = args[index + 1]
		elif args[index].begins_with("--size="):
			var parts := args[index].trim_prefix("--size=").split("x")
			SHOT = Vector2i(int(parts[0]), int(parts[1]))
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", 1793000000)
	call_deferred("_run")


func _run() -> void:
	if _out.is_empty():
		push_error("[STORE] --out <folder> is required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	var scale := minf(float(SHOT.x) / LOGICAL.x, float(SHOT.y) / LOGICAL.y)
	_vp = SubViewport.new()
	_vp.size = Vector2i(roundi(LOGICAL.x * scale), roundi(LOGICAL.y * scale))
	_vp.size_2d_override = LOGICAL
	_vp.size_2d_override_stretch = true
	_vp.snap_2d_transforms_to_pixel = true
	_vp.snap_2d_vertices_to_pixel = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	_vp.add_child(_main)
	await _frames(4)
	var engine: Object = _main.get("_engine")
	var state: Dictionary = StateFactory.create(20261106, "세라")
	_main.call("_adopt_engine_result", engine.call("initialize_from_state", state))
	engine.call("advance_slots", 197, 1793000000)
	# 첫 방문 안내는 이미 본 상태로, 기력과 골드는 보통 수준으로 맞춰 평소 플레이 화면을 보인다.
	var played: Dictionary = engine.call("get_state")
	(played["unlocks"] as Dictionary)["tipsSeen"] = ["plan", "growth", "challenge", "record", "contracts", "world", "shop", "events", "relations", "rules", "bannedTags", "customWeights", "league"]
	(played["meters"] as Dictionary)["energy"] = 80.0
	(played["meters"] as Dictionary)["stress"] = 12.0
	(played["bigValues"] as Dictionary)["gold"] = BigValue.from_number(4800)
	_main.call("_adopt_engine_result", engine.call("initialize_from_state", played))
	_main.call("_toggle_setting", true, "reducedMotion")
	_main.call("_refresh_chrome")
	_main.call("_show_tab", "home")
	await _shot("01-home")
	# 직접 실행은 시간을 진행시키므로 결과 창은 다른 화면을 모두 찍은 뒤 마지막에 찍는다(파일 순서는 등록정보 순서).
	_main.set("_activity_filter", "education")
	_main.call("_show_tab", "activity")
	await _shot("03-activity")
	_main.call("_show_tab", "growth")
	await _shot("04-growth")
	_main.call("_open_sheet", "world")
	await _shot("05-world")
	_main.call("_close_sheet")
	_main.call("_show_tab", "record")
	await _shot("06-record")
	_main.call("_show_tab", "home")
	_main.call("_run_activity", "EDU_LITERATURE")
	await _shot("02-result", false)
	_cleanup()
	print("[STORE] PASS shots=6 out=%s" % _out)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


# hide_feedback=false면 결과 창은 둔다. 알림 띠는 스크린샷에서 숨긴다.
func _shot(name: String, hide_feedback: bool = true) -> void:
	await _frames(6)
	var toast := _main.get("_toast_panel") as Control
	if toast != null:
		toast.visible = false
	if hide_feedback:
		(_main.get("_result_feedback_layer") as Control).call("dismiss")
	await _frames(2)
	await RenderingServer.frame_post_draw
	var rendered := _vp.get_texture().get_image()
	rendered.convert(Image.FORMAT_RGBA8)
	var image := Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGBA8)
	image.fill(MARGIN)
	image.blit_rect(rendered, Rect2i(Vector2i.ZERO, rendered.get_size()), (SHOT - rendered.get_size()) / 2)
	image.convert(Image.FORMAT_RGB8)
	image.save_png(_out.path_join("%s.png" % name))
	print("[STORE] shot ", name)


func _cleanup() -> void:
	for path: String in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
