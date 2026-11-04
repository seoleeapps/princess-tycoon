extends Control

const PixelTheme = preload("res://src/ui/pixel/pixel_theme.gd")
const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const ICON_DIR := "res://assets/pixel/icons/"
const STEP := 2.0

const MAX_DETAIL_LINES := 4
const STATIC_VISIBLE_SECONDS := 4.0

var _active_panel: PanelContainer
var _active_tween: Tween
var _active_serial := 0
var _reduced_motion := false
var _static_hide_timer: Timer
var _static_hide_serial := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_static_hide_timer = Timer.new()
	_static_hide_timer.one_shot = true
	_static_hide_timer.ignore_time_scale = true
	_static_hide_timer.timeout.connect(_on_static_hide_timeout)
	add_child(_static_hide_timer)


func present(payload: Dictionary, reduced_motion: bool) -> void:
	if payload.is_empty():
		return
	_reduced_motion = reduced_motion
	_clear_active()
	_active_serial += 1
	var serial := _active_serial
	var panel := _build_panel(payload)
	_active_panel = panel
	add_child(panel)
	if _reduced_motion:
		_apply_static_state(panel)
		_schedule_static_hide(serial)
	else:
		panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		call_deferred("_animate_active", serial)


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if not enabled or _active_panel == null or not is_instance_valid(_active_panel):
		return
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	_apply_static_state(_active_panel)
	_schedule_static_hide(_active_serial)


func has_active_feedback() -> bool:
	return _active_panel != null and is_instance_valid(_active_panel) and _active_panel.visible


func active_feedback_kind() -> String:
	if not has_active_feedback():
		return ""
	return str(_active_panel.get_meta("feedback_kind", ""))


func active_motion_mode() -> String:
	if not has_active_feedback():
		return ""
	return str(_active_panel.get_meta("motion_mode", ""))


func active_detail_count() -> int:
	if not has_active_feedback():
		return 0
	return int(_active_panel.get_meta("detail_count", 0))


func active_floating_stat_count() -> int:
	if not has_active_feedback():
		return 0
	return int(_active_panel.get_meta("floating_stat_count", 0))


func _build_panel(payload: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ResultFeedback"
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.14
	panel.anchor_bottom = 0.14
	panel.offset_bottom = 218.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 80
	panel.theme_type_variation = PixelTheme.panel_variation({"gold": "window_gold", "coral": "window_accent"}.get(str(payload.get("tone", "raised")), "window"))
	panel.set_meta("feedback_kind", str(payload.get("kind", "activity")))
	panel.set_meta("payload", payload.duplicate(true))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.custom_minimum_size.x = 300.0
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

	var heading := HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation", 8)
	content.add_child(heading)
	heading.add_child(_kind_icon(str(payload.get("kind", "activity"))))
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.theme_type_variation = PixelTheme.panel_variation("chip")
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_label := _label(str(payload.get("badge", "성장")), 16, PixelTokens.INK, HORIZONTAL_ALIGNMENT_CENTER)
	badge_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_child(badge_label)
	heading.add_child(badge)
	var headline := _label(str(payload.get("headline", "활동 완료")), 24, PixelTokens.INK)
	headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	headline.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(headline)

	var floating_stat_count := 0
	var stat_row := HBoxContainer.new()
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 6)
	for raw_stat: Variant in payload.get("floatingStats", []) as Array:
		if floating_stat_count >= 3:
			break
		var stat_text := str(raw_stat).strip_edges()
		if stat_text.is_empty():
			continue
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.theme_type_variation = PixelTheme.panel_variation("inset")
		chip.add_to_group("result_stat_chip")
		chip.set_meta("stat_index", floating_stat_count)
		var stat_label := _label(stat_text, 16, PixelTokens.POSITIVE, HORIZONTAL_ALIGNMENT_CENTER)
		stat_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		stat_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.add_child(stat_label)
		stat_row.add_child(chip)
		floating_stat_count += 1
	if floating_stat_count > 0:
		content.add_child(stat_row)
	else:
		stat_row.free()
	panel.set_meta("floating_stat_count", floating_stat_count)

	var detail_count := 0
	for raw_line: Variant in payload.get("details", []) as Array:
		if detail_count >= MAX_DETAIL_LINES:
			break
		var line := str(raw_line).strip_edges()
		if line.is_empty():
			continue
		content.add_child(_label(line, 16, PixelTokens.INK_MUTED))
		detail_count += 1
	panel.set_meta("detail_count", detail_count)
	return panel


# 도트 화면에 맞춘 계단식 연출: 창이 2px 단위로 8px 올라오며 3단계로 나타나고, 능력치 칩은 하나씩 켜진다.
func _animate_active(serial: int) -> void:
	if serial != _active_serial or _active_panel == null or not is_instance_valid(_active_panel):
		return
	if _reduced_motion:
		_apply_static_state(_active_panel)
		_schedule_static_hide(serial)
		return
	var panel := _active_panel
	panel.set_meta("motion_mode", "animated")
	var rest_y := panel.position.y
	var floating_chips := _floating_stat_chips(panel)
	for chip: Control in floating_chips:
		chip.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_active_tween = create_tween()
	_active_tween.tween_method(_step_panel.bind(panel, rest_y), 0.0, 1.0, 0.2)
	for index: int in range(floating_chips.size()):
		_active_tween.tween_interval(0.06)
		_active_tween.tween_callback(_show_chip.bind(floating_chips[index]))
	_active_tween.tween_interval(2.2)
	_active_tween.tween_method(_fade_panel.bind(panel), 1.0, 0.0, 0.24)
	_active_tween.finished.connect(_finish_if_current.bind(serial))


func _step_panel(progress: float, panel: Control, rest_y: float) -> void:
	if not is_instance_valid(panel):
		return
	var steps := floorf(progress * 4.0)
	panel.position.y = rest_y + (4.0 - steps) * STEP
	panel.modulate.a = minf(1.0, ceilf(progress * 3.0) / 3.0)


func _fade_panel(alpha: float, panel: Control) -> void:
	if is_instance_valid(panel):
		panel.modulate.a = ceilf(alpha * 3.0) / 3.0


func _show_chip(chip: Control) -> void:
	if is_instance_valid(chip):
		chip.modulate = Color.WHITE


func _apply_static_state(panel: PanelContainer) -> void:
	panel.modulate = Color.WHITE
	for chip: Control in _floating_stat_chips(panel):
		chip.modulate = Color.WHITE
	panel.set_meta("motion_mode", "static")


func _floating_stat_chips(panel: PanelContainer) -> Array[Control]:
	var result: Array[Control] = []
	for node: Node in panel.find_children("*", "PanelContainer", true, false):
		if node.is_in_group("result_stat_chip"):
			result.append(node as Control)
	return result


func _schedule_static_hide(serial: int) -> void:
	_static_hide_serial = serial
	_static_hide_timer.start(STATIC_VISIBLE_SECONDS)


func _on_static_hide_timeout() -> void:
	_finish_if_current(_static_hide_serial)


func _finish_if_current(serial: int) -> void:
	if serial != _active_serial:
		return
	_clear_active()


func _clear_active() -> void:
	if _static_hide_timer != null:
		_static_hide_timer.stop()
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	if _active_panel != null and is_instance_valid(_active_panel):
		_active_panel.visible = false
		_active_panel.queue_free()
	_active_panel = null


func _kind_icon(kind: String) -> TextureRect:
	var icon_name: String = {"challenge": "record", "review": "growth", "title": "record", "adventure": "world"}.get(kind, "activity")
	var image := (load(ICON_DIR + icon_name + ".png") as Texture2D).get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var rect := TextureRect.new()
	rect.texture = ImageTexture.create_from_image(image)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font_size >= 20:
		label.add_theme_font_override("font", PixelTheme.title_font())
		label.add_theme_font_size_override("font_size", PixelTheme.TITLE_SIZE)
	else:
		label.add_theme_font_size_override("font_size", PixelTheme.BODY_SIZE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
