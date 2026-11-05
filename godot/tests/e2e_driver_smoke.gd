extends SceneTree

# E2E 드라이버 자체 점검. 렌더링 모드의 실제 창은 누르는 사이 포커스를 잃을 수 있고, 그러면 엔진이 누름을 취소한다.
# 드라이버는 그 탭을 다시 눌러야 한다. headless에서 엔진의 포커스 손실 처리를 직접 일으켜 확인한다.
const E2EDriver := preload("res://tests/e2e/e2e_driver.gd")
const OUT_DIR := "user://e2e/driver_smoke"

var _failures: Array[String] = []
var _passes := 0
var _presses := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[E2E-DRIVER] tap and stretch self-check")
	var e2e = E2EDriver.new(self, Vector2i(720, 1280), ProjectSettings.globalize_path(OUT_DIR), false)
	_check(e2e.logical_size == Vector2i(390, 844) and e2e.viewport.size_2d_override == Vector2i(390, 844), "기기 화면에 프로젝트 늘림(390×844 기준) 적용")
	var button := Button.new()
	button.text = "탭"
	button.position = Vector2(100, 100)
	button.size = Vector2(120, 60)
	button.pressed.connect(func() -> void: _presses += 1)
	e2e.viewport.add_child(button)
	await process_frame
	await e2e.tap(button)
	_check(_presses == 1, "기기 좌표로 넣은 탭이 장면 좌표의 버튼을 누름")
	_presses = 0
	var injected := [false]
	var lose_focus := func() -> void:
		if not injected[0] and button.is_pressed():
			injected[0] = true
			e2e.viewport.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			root.focus_exited.emit()
	process_frame.connect(lose_focus)
	await e2e.tap(button)
	process_frame.disconnect(lose_focus)
	_check(injected[0] and _presses == 1, "누르는 사이 창 포커스를 잃어 취소된 탭은 한 번 다시 누름 (눌림 %d)" % _presses)
	_cleanup()
	if _failures.is_empty():
		print("[E2E-DRIVER] PASS checks=%d" % _passes)
		quit(0)
		return
	print("[E2E-DRIVER] FAIL passed=%d failed=%d" % [_passes, _failures.size()])
	quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("[PASS] %s" % label)
	else:
		_failures.append(label)
		push_error("[FAIL] %s" % label)


func _cleanup() -> void:
	var dir := ProjectSettings.globalize_path(OUT_DIR)
	if FileAccess.file_exists(dir.path_join("journey.json")):
		DirAccess.remove_absolute(dir.path_join("journey.json"))
	DirAccess.remove_absolute(dir)
