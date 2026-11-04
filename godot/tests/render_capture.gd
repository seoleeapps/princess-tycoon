extends SceneTree

const LOGICAL_SIZE := Vector2i(390, 844)

var _capture_size := LOGICAL_SIZE
var _output_path := "/tmp/princess-tycoon-render.png"
var _save_path := "user://qa_render_capture.json"
var _capture_result_feedback := false


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var pieces := argument.trim_prefix("--size=").split("x")
			if pieces.size() == 2:
				_capture_size = Vector2i(maxi(1, int(pieces[0])), maxi(1, int(pieces[1])))
		if argument.begins_with("--output="):
			_output_path = argument.trim_prefix("--output=")
		if argument == "--result-feedback":
			_capture_result_feedback = true
	_save_path = "user://qa_render_%dx%d.json" % [_capture_size.x, _capture_size.y]
	_cleanup_save()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", _save_path)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("[RENDER] main scene load failed")
		quit(1)
		return
	# 실제 기기처럼 390×844 좌표계를 기기 해상도에서 직접 그린다(canvas_items + keep).
	# 글자와 도트를 확대하지 않고 기기 배율로 래스터해 정수가 아닌 배율의 도트 굵기를 그대로 보여 준다.
	var scale := minf(float(_capture_size.x) / LOGICAL_SIZE.x, float(_capture_size.y) / LOGICAL_SIZE.y)
	var render_size := Vector2i(roundi(LOGICAL_SIZE.x * scale), roundi(LOGICAL_SIZE.y * scale))
	var device_viewport := SubViewport.new()
	device_viewport.name = "Device%dx%d" % [_capture_size.x, _capture_size.y]
	device_viewport.size = render_size
	device_viewport.size_2d_override = LOGICAL_SIZE
	device_viewport.size_2d_override_stretch = true
	if "oversampling" in device_viewport:
		device_viewport.set("oversampling", true)
	device_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	device_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	device_viewport.disable_3d = true
	root.add_child(device_viewport)
	var main := packed.instantiate() as Control
	device_viewport.add_child(main)

	for _frame: int in range(4):
		await process_frame
	if _capture_result_feedback:
		main.call("_complete_current_activity")
	# 결과 창은 2px 단위로 올라오고 능력치 칩이 하나씩 켜지므로 다 나타난 뒤(약 0.6초) 찍는다.
	for _frame: int in range(40 if _capture_result_feedback else 4):
		await process_frame
	await RenderingServer.frame_post_draw
	var texture := device_viewport.get_texture()
	if texture == null:
		push_error("[RENDER] viewport texture unavailable")
		_cleanup_save()
		quit(1)
		return
	var rendered := texture.get_image()
	var image := Image.create(_capture_size.x, _capture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	if rendered != null:
		rendered.convert(Image.FORMAT_RGBA8)
		image.blit_rect(rendered, Rect2i(Vector2i.ZERO, rendered.get_size()), (_capture_size - rendered.get_size()) / 2)
	if rendered == null or image.get_size() != _capture_size:
		push_error("[RENDER] size mismatch expected=%s actual=%s" % [str(_capture_size), str(image.get_size() if image != null else Vector2i.ZERO)])
		_cleanup_save()
		quit(1)
		return
	var error := image.save_png(_output_path)
	_cleanup_save()
	if error != OK:
		push_error("[RENDER] png save failed error=%d" % error)
		quit(1)
		return
	device_viewport.queue_free()
	await process_frame
	print("[RENDER] PASS size=%dx%d output=%s" % [_capture_size.x, _capture_size.y, _output_path])
	quit(0)


func _cleanup_save() -> void:
	var absolute := ProjectSettings.globalize_path(_save_path)
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
