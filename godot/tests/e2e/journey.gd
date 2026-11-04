extends SceneTree

# 실제 main.tscn을 띄우고 화면 좌표 탭·드래그만으로 12개 기능 경로를 잇는 여정.
# 플랫폼 경계는 저장 경로(princess_tycoon/testing/save_path)와 시계(princess_tycoon/testing/fixed_unix)만 바꾼다.
#   godot --headless --fixed-fps 60 --path godot --script res://tests/e2e/journey.gd -- --out <dir> [--viewport=390x844]
#   godot --fixed-fps 60 --path godot --script res://tests/e2e/journey.gd -- --out <dir> --capture   # 장면별 PNG

const E2EDriver := preload("res://tests/e2e/e2e_driver.gd")
const MAIN_SCENE := "res://scenes/main.tscn"
const START_UNIX := 1_800_000_000
const OFFLINE_SECONDS := 3600
const TRAINEE_NAME := "세라"

var e2e: E2EDriver
var _save_path := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "user://e2e/out"
	var view_size := Vector2i(390, 844)
	for index in args.size():
		var arg := args[index]
		if arg == "--out" and index + 1 < args.size():
			out = args[index + 1]
		elif arg.begins_with("--viewport="):
			var parts := arg.trim_prefix("--viewport=").split("x")
			view_size = Vector2i(int(parts[0]), int(parts[1]))
	var run_id := "%dx%d" % [view_size.x, view_size.y]
	_save_path = "user://e2e/%s/save.json" % run_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_save_path.get_base_dir()))
	_clear_save()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", _save_path)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", START_UNIX)

	e2e = E2EDriver.new(self, view_size, out, args.has("--capture"))
	var main: Control = await _mount_main()
	await _first_session(main)
	await _return_offline(main)
	_clear_save()
	quit(e2e.finish({
		"viewportId": run_id,
		"fixedUnixStart": START_UNIX,
		"sourceSha": OS.get_environment("SOURCE_SHA"),
	}))


func _first_session(main: Control) -> void:
	e2e.begin("first-session", ["home", "profile", "plan", "activity", "result", "growth", "record", "world", "shop", "settings", "menu", "event"])
	e2e.step("starts on home", _screen(main) == "home")
	await e2e.shot("01-home")

	await _tap_id(main, "menu", "open menu")
	e2e.step("menu sheet visible", _find_screen(main, "menu") != null)
	await e2e.shot("02-menu")
	await _tap_id(main, "menu_profile", "open new trainee")
	e2e.step("profile sheet visible", _find_screen(main, "profile") != null)
	var name_edit := _find_visible(main, func(node: Node) -> bool: return node is LineEdit) as LineEdit
	if e2e.step("name field visible", name_edit != null):
		e2e.step("tap name field", await e2e.tap(name_edit))
		name_edit.select_all()
		name_edit.delete_text(0, name_edit.text.length())
		name_edit.insert_text_at_caret(TRAINEE_NAME)
	await e2e.shot("03-profile")
	await _tap_id(main, "create_balanced", "create trainee with balanced direction")
	await e2e.frames(4)
	e2e.expect_equal("trainee name saved", str(_state(main).get("traineeName", "")), TRAINEE_NAME)
	e2e.expect_equal("first direction", str(_read(main, ["growthPolicy", "preset"], "")), "balanced")
	e2e.step("profile sheet closed", _find_screen(main, "profile") == null)
	e2e.expect_equal("new trainee has no unearned titles", (_read(main, ["careerTitles"], {}) as Dictionary).size(), 0)
	e2e.expect_equal("new trainee has no unearned mastery", (_read(main, ["mastery"], {}) as Dictionary).size(), 0)
	await e2e.shot("04-home-new-trainee")

	await _tap_id(main, "open_world", "open world sheet")
	e2e.step("world sheet visible", _find_screen(main, "world") != null)
	await e2e.shot("05-world")
	var world_id := _first_enabled_id(main, "world_")
	if e2e.step("unlocked world action found", not world_id.is_empty(), _button_states(main, "world_")):
		var slot_world := int(_read(main, ["time", "slot"], 0))
		await _tap_id(main, world_id, "start world action")
		e2e.step("world action advanced time", int(_read(main, ["time", "slot"], 0)) > slot_world)
		await e2e.shot("06-world-result")
		# 시트 위에 뜬 결과 창을 누르면 창만 닫히고 시트는 그대로여야 한다(아래 시트 버튼이 눌리지 않음).
		var card := _result_layer(main).get("_active_panel") as Control
		if e2e.step("result card shown over world sheet", card != null and bool(_result_layer(main).call("has_active_feedback")) and card.mouse_filter == Control.MOUSE_FILTER_STOP):
			e2e.step("tap result card over sheet", await e2e.tap(card))
			await e2e.frames(3)
			e2e.step("card closes and world sheet stays", not bool(_result_layer(main).call("has_active_feedback")) and _find_screen(main, "world") != null)
	await _close_sheet(main)

	await _tap_id(main, "tab_plan", "open plan tab")
	e2e.step("plan tab visible", _screen(main) == "plan")
	await _tap_id(main, "preset_scholar", "pick scholar direction")
	e2e.expect_equal("direction changed", str(_read(main, ["growthPolicy", "preset"], "")), "scholar")
	var stress_before := float(_read(main, ["growthPolicy", "maxStress"], 0.0))
	await _tap_id(main, "step_maxStress_plus", "raise max stress one step")
	e2e.expect_equal("max stress stepped", float(_read(main, ["growthPolicy", "maxStress"], 0.0)), minf(95.0, stress_before + 1.0))
	await e2e.shot("07-plan")

	await _tap_id(main, "tab_activity", "open activity tab")
	e2e.step("activity tab visible", _screen(main) == "activity")
	await e2e.shot("08-activity")
	var scroll := _page_scroll(main)
	var slot_before := int(_read(main, ["time", "slot"], 0))
	var gold_before := str(_read(main, ["bigValues", "gold"], {}))
	if e2e.step("activity list scroll exists", scroll != null):
		var start := _first_button_point(scroll)
		await e2e.drag(start, start - Vector2(0, 260), 12, 0.25)
		await e2e.frames(4)
		e2e.step("list scrolls when the drag starts on a card button", scroll.scroll_vertical > 0, "scroll=%d" % scroll.scroll_vertical)
		e2e.step("drag does not run an activity", int(_read(main, ["time", "slot"], 0)) == slot_before and str(_read(main, ["bigValues", "gold"], {})) == gold_before)
		# 자동 진행이 다음 슬롯을 처리하며 목록을 다시 그려도 스크롤 위치가 유지돼야 한다.
		var kept_scroll := scroll.scroll_vertical
		var slot_auto := int(_read(main, ["time", "slot"], 0))
		e2e.step("auto run advances a slot", await e2e.wait_for(func() -> bool: return int(_read(main, ["time", "slot"], 0)) > slot_auto, 420))
		await e2e.frames(3)
		var scroll_after := _page_scroll(main)
		e2e.step("list keeps scroll after auto refresh", scroll_after != null and absi(scroll_after.scroll_vertical - kept_scroll) <= 2, "before=%d after=%d" % [kept_scroll, scroll_after.scroll_vertical if scroll_after != null else -1])
	await e2e.shot("09-activity-scrolled")
	var run_id := _first_enabled_id(main, "activity_run_")
	for attempt in 3:
		if not run_id.is_empty():
			break
		# 예정된 시험이 수동 활동을 막으면 플레이어처럼 추천 활동을 먼저 실행한다.
		await _tap_id(main, "run_recommended", "run the scheduled recommendation first")
		await e2e.frames(4)
		run_id = _first_enabled_id(main, "activity_run_")
	if e2e.step("unlocked activity found", not run_id.is_empty(), "%s | meters=%s gold=%s locks=%s" % [_button_states(main, "activity_run_"), JSON.stringify(_read(main, ["meters"], {})), JSON.stringify(_read(main, ["bigValues", "gold"], {})), _lock_labels(main)]):
		var mastery_key := run_id.trim_prefix("activity_run_")
		var mastery_before := int(_read(main, ["mastery", mastery_key], 0))
		await _tap_id(main, run_id, "run one activity")
		e2e.step("result feedback shown", await e2e.wait_for(func() -> bool: return _result_layer(main).call("has_active_feedback"), 30))
		var toast_label = main.get("_toast_label")
		e2e.step("activity mastery increased", int(_read(main, ["mastery", mastery_key], 0)) > mastery_before,
			"activity=%s mastery=%s toast=%s" % [mastery_key, JSON.stringify(_read(main, ["mastery"], {})), "" if toast_label == null else (toast_label as Label).text])
		await e2e.shot("10-activity-result")
	var detail_id := _first_enabled_id(main, "activity_run_").trim_prefix("activity_run_")
	if e2e.step("unlocked activity for detail", not detail_id.is_empty()):
		await _tap_id(main, "activity_detail_" + detail_id, "open activity detail")
		e2e.step("activity detail sheet visible", _find_screen(main, "activity_detail") != null)
		await e2e.shot("10b-activity-detail")
		var queue_before := (_read(main, ["activityQueue"], []) as Array).size()
		await _tap_id(main, "detail_queue", "queue from detail")
		e2e.expect_equal("activity queued", (_read(main, ["activityQueue"], []) as Array).size(), queue_before + 1)
		await _close_sheet(main)

	await _tap_id(main, "tab_growth", "open growth tab")
	e2e.step("growth tab visible", _screen(main) == "growth")
	await e2e.shot("11-growth")
	await _tap_id(main, "tab_record", "open record tab")
	e2e.step("record tab visible", _screen(main) == "record")
	await e2e.shot("12-record")

	await _open_from_menu(main, "menu_shop", "shop")
	await e2e.shot("13-shop")
	var tea_before := _inventory_count(main, "ITEM_TEA")
	await _tap_id(main, "buy_ITEM_TEA", "buy a consumable")
	e2e.expect_equal("consumable added", _inventory_count(main, "ITEM_TEA"), tea_before + 1)
	# 구매 뒤 시트를 다시 그려도 목록 위치가 유지돼야 한다.
	await e2e.frames(3)
	var shop_scroll := _sheet_scroll(main, "shop")
	e2e.step("shop keeps scroll after purchase", shop_scroll != null and shop_scroll.scroll_vertical > 0, "scroll=%d" % (shop_scroll.scroll_vertical if shop_scroll != null else -1))
	await _close_sheet(main)

	await _open_from_menu(main, "menu_settings", "settings")
	await e2e.shot("14-settings")
	var motion_toggle := _find_id(main, "toggle_reducedMotion")
	if e2e.step("reduced motion toggle visible", motion_toggle != null):
		e2e.step("tap reduced motion", await e2e.tap(motion_toggle))
		e2e.expect_equal("reduced motion on", bool(_read(main, ["settings", "reducedMotion"], false)), true)
	var contrast_toggle := _find_id(main, "toggle_highContrast")
	if e2e.step("high contrast toggle visible", contrast_toggle != null):
		e2e.step("tap high contrast", await e2e.tap(contrast_toggle))
		e2e.expect_equal("high contrast on", bool(_read(main, ["settings", "highContrast"], false)), true)
		await e2e.frames(3)
		await e2e.shot("14b-settings-high-contrast")
		e2e.step("tap high contrast off", await e2e.tap(_find_id(main, "toggle_highContrast")))
		e2e.expect_equal("high contrast off", bool(_read(main, ["settings", "highContrast"], true)), false)
	await _close_sheet(main)

	await _tap_id(main, "status_detail", "open status detail")
	var toast := main.get("_toast_label") as Label
	e2e.step("status detail shows full reason", toast != null and toast.is_visible_in_tree() and toast.text.contains("이유 ·"), "" if toast == null else toast.text)
	await _tap_id(main, "pause", "pause auto run")
	e2e.expect_equal("auto run paused", bool(_read(main, ["settings", "autoRun"], true)), false)
	await e2e.shot("15-paused")
	await _tap_id(main, "pause", "resume auto run")
	e2e.expect_equal("auto run resumed", bool(_read(main, ["settings", "autoRun"], false)), true)

	await _open_from_menu(main, "menu_event", "event")
	await e2e.shot("16-event")
	await _close_sheet(main)
	await _tap_id(main, "menu", "open menu for save")
	await _tap_id(main, "menu_save", "save now")
	await _close_sheet(main)
	e2e.end()


func _return_offline(main: Control) -> void:
	e2e.begin("return-offline", ["save", "offline", "event", "continue"])
	var slot_saved := int(_read(main, ["time", "slot"], 0))
	await e2e.unmount(main)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", START_UNIX + OFFLINE_SECONDS)
	var again: Control = await _mount_main()
	e2e.expect_equal("name restored", str(_state(again).get("traineeName", "")), TRAINEE_NAME)
	e2e.expect_equal("direction restored", str(_read(again, ["growthPolicy", "preset"], "")), "scholar")
	e2e.step("offline sheet opens on return", await e2e.wait_for(func() -> bool: return _find_screen(again, "offline") != null, 30))
	e2e.step("offline slots pending", int(_state(again).get("pendingOfflineSlots", 0)) > 0)
	await e2e.shot("17-offline")
	var home_before := _content_page(again)
	await _tap_id(again, "offline_collect", "collect offline result")
	e2e.expect_equal("offline slots settled", int(_state(again).get("pendingOfflineSlots", -1)), 0)
	e2e.step("offline sheet lists what changed", _find_label_prefix(again, "능력치 합 +") != null)
	e2e.step("home redrawn with settled values", _content_page(again) != home_before)
	e2e.step("time advanced offline", int(_read(again, ["time", "slot"], 0)) > slot_saved)
	await e2e.shot("18-offline-collected")
	await _close_sheet(again)

	await _tap_id(again, "open_event", "open event inbox")
	e2e.step("event sheet visible", _find_screen(again, "event") != null)
	var inbox_before := (_read(again, ["eventInbox"], []) as Array).size()
	if inbox_before > 0:
		await e2e.shot("19-event-choice")
		await _tap_id(again, "event_choice_0", "choose first event option")
		e2e.step("event resolved", (_read(again, ["eventInbox"], []) as Array).size() < inbox_before)
	else:
		e2e.step("empty inbox explains automatic progress", _find_label(again, "대기 중인 이벤트가 없습니다.") != null)
	await _close_sheet(again)

	await _open_from_menu(again, "menu_continue", "continue")
	await e2e.shot("20-continue")
	await _tap_id(again, "continue_game", "continue saved trainee")
	e2e.step("continue returns home", _screen(again) == "home")
	e2e.expect_equal("continued trainee", str(_state(again).get("traineeName", "")), TRAINEE_NAME)
	e2e.end()
	await e2e.unmount(again)


func _mount_main() -> Control:
	var packed := load(MAIN_SCENE) as PackedScene
	var main := packed.instantiate() as Control
	await e2e.mount(main)
	await e2e.frames(4)
	return main


func _open_from_menu(main: Control, menu_id: String, screen_id: String) -> void:
	await _tap_id(main, "menu", "open menu")
	await _tap_id(main, menu_id, "menu → %s" % screen_id)
	e2e.step("%s sheet visible" % screen_id, _find_screen(main, screen_id) != null)


func _close_sheet(main: Control) -> void:
	var close := _find_id(main, "sheet_close")
	if close == null:
		return
	await _dismiss_covering_feedback(main, close)
	e2e.step("close sheet", await e2e.tap(close))
	await e2e.frames(3)


func _tap_id(main: Control, ui_id: String, label: String) -> bool:
	var control := _find_id(main, ui_id)
	if control != null:
		await _dismiss_covering_feedback(main, control)
	var ok := control != null and await e2e.tap(control)
	e2e.step(label, ok, "" if ok else "ui_id=%s not tappable" % ui_id)
	await e2e.frames(3)
	return ok


# 결과 창이 누를 버튼을 가리면 사람처럼 창을 눌러 닫는다(결과 창은 탭을 받아 아래로 전달하지 않는다).
func _dismiss_covering_feedback(main: Control, control: Control) -> void:
	var layer := _result_layer(main)
	if layer == null or not layer.call("has_active_feedback"):
		return
	var panel := layer.get("_active_panel") as Control
	if panel == null or panel.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	await e2e.scroll_into_view(control)
	if panel.get_global_rect().intersects(control.get_global_rect()):
		e2e.step("dismiss result card covering target", await e2e.tap(panel))
		await e2e.frames(2)


func _find_id(root: Node, ui_id: String) -> Control:
	return _find_visible(root, func(node: Node) -> bool: return str(node.get_meta("ui_id", "")) == ui_id) as Control


func _first_enabled_id(root: Node, prefix: String) -> String:
	var found := _find_visible(root, func(node: Node) -> bool:
		return node is BaseButton and not (node as BaseButton).disabled and str(node.get_meta("ui_id", "")).begins_with(prefix))
	return "" if found == null else str(found.get_meta("ui_id", ""))


# 화면 맨 위 시트가 우선이다. 시트가 열려 있으면 그 아래 페이지 버튼은 누를 수 없다.
func _find_visible(root: Node, predicate: Callable) -> Node:
	var sheet := _top_sheet(root)
	return _search(sheet if sheet != null else root, predicate)


func _search(node: Node, predicate: Callable) -> Node:
	if node.is_queued_for_deletion():
		return null
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return null
	if predicate.call(node):
		return node
	for child in node.get_children():
		var found := _search(child, predicate)
		if found != null:
			return found
	return null


func _top_sheet(main: Node) -> Node:
	var layer = main.get("_modal_layer")
	if layer == null:
		return null
	var top: Node = null
	for child in (layer as Node).get_children():
		if child.is_queued_for_deletion() or not child.has_meta("screen_id"):
			continue
		top = child
	return top


func _find_screen(main: Node, screen_id: String) -> Node:
	var layer = main.get("_modal_layer")
	if layer == null:
		return null
	for child in (layer as Node).get_children():
		if not child.is_queued_for_deletion() and str(child.get_meta("screen_id", "")) == screen_id:
			return child
	return null


func _find_label_prefix(main: Node, prefix: String) -> Node:
	return _find_visible(main, func(node: Node) -> bool: return node is Label and (node as Label).text.begins_with(prefix))


func _content_page(main: Node) -> Node:
	for child in (main.get("_content_host") as Node).get_children():
		if not child.is_queued_for_deletion():
			return child
	return null


func _find_label(main: Node, text_value: String) -> Node:
	return _find_visible(main, func(node: Node) -> bool: return node is Label and (node as Label).text == text_value)


func _page_scroll(main: Node) -> ScrollContainer:
	var host = main.get("_content_host")
	return _search(host, func(node: Node) -> bool: return node is ScrollContainer) as ScrollContainer


func _sheet_scroll(main: Node, screen_id: String) -> ScrollContainer:
	var sheet := _find_screen(main, screen_id)
	if sheet == null:
		return null
	for found in sheet.find_children("*", "ScrollContainer", true, false):
		return found as ScrollContainer
	return null


func _first_button_point(scroll: ScrollContainer) -> Vector2:
	var view := scroll.get_global_rect()
	var button := _search(scroll, func(node: Node) -> bool:
		if not node is BaseButton:
			return false
		var rect := (node as Control).get_global_rect()
		return rect.position.y > view.position.y + view.size.y * 0.45 and rect.end.y < view.end.y) as Control
	if button == null:
		return view.get_center() + Vector2(0, view.size.y * 0.25)
	return button.get_global_rect().get_center()


func _button_states(root: Node, prefix: String) -> String:
	var parts: Array[String] = []
	var sheet := _top_sheet(root)
	_collect_buttons(sheet if sheet != null else root, prefix, parts)
	return ", ".join(parts)


func _collect_buttons(node: Node, prefix: String, parts: Array[String]) -> void:
	if node is BaseButton and str(node.get_meta("ui_id", "")).begins_with(prefix):
		parts.append("%s:%s%s" % [node.get_meta("ui_id"), "off" if (node as BaseButton).disabled else "on", "" if (node as CanvasItem).is_visible_in_tree() else ":hidden"])
	for child in node.get_children():
		_collect_buttons(child, prefix, parts)


func _lock_labels(root: Node) -> String:
	var parts: Array[String] = []
	_collect_locks(root, parts)
	return " / ".join(parts)


func _collect_locks(node: Node, parts: Array[String]) -> void:
	if node is Label and (node as Label).text.begins_with("잠금") and not node.is_queued_for_deletion():
		parts.append((node as Label).text)
	for child in node.get_children():
		_collect_locks(child, parts)


func _result_layer(main: Node) -> Node:
	return main.get("_result_feedback_layer") as Node


func _screen(main: Node) -> String:
	return str(main.get_meta("screen_id", ""))


func _state(main: Node) -> Dictionary:
	return main.get("_state") as Dictionary


func _read(main: Node, path: Array, fallback: Variant) -> Variant:
	var current: Variant = _state(main)
	for key in path:
		if not current is Dictionary or not (current as Dictionary).has(key):
			return fallback
		current = (current as Dictionary)[key]
	return current


func _inventory_count(main: Node, item_id: String) -> int:
	for stack in _read(main, ["inventory"], []):
		if stack is Dictionary and str(stack.get("id", "")) == item_id:
			return int(stack.get("count", 0))
	return 0


func _clear_save() -> void:
	var absolute := ProjectSettings.globalize_path(_save_path)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
