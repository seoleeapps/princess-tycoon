extends SceneTree

const SAVE := "user://qa_safe_area_lifecycle.json"
const NOW := 1_800_000_000
var checks := 0
var failed := 0

class EnterProbe:
	extends "res://src/ui/main_screen.gd"
	var pre_ready_unchanged := false
	func _enter_tree() -> void:
		var before := JSON.stringify(_state)
		notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
		notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
		pre_ready_unchanged = JSON.stringify(_state) == before

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", NOW)
	ProjectSettings.set_setting("princess_tycoon/testing/safe_area_insets", Vector2(14, 8))
	root.size = Vector2i(390, 844)
	var main := EnterProbe.new()
	var untouched := JSON.stringify(main.get("_state"))
	_check(main.get_viewport() == null and not main.is_node_ready(), "SA-01 초기화 전에는 Viewport 없음")
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not bool(main.get("_application_focused")), "SA-01 초기화 전 포커스 이탈 상태 보존")
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	main.call("_apply_safe_area")
	_check(bool(main.get("_application_focused")) and not bool(main.get("_application_paused")), "SA-01 초기화 전 마지막 포커스·정지 상태 보존")
	_check(JSON.stringify(main.get("_state")) == untouched and not FileAccess.file_exists(SAVE), "SA-01 초기화 전 UI·상태·저장 처리 없음")
	root.add_child(main)
	await process_frame
	await process_frame
	_check(main.pre_ready_unchanged, "SA-01 트리 진입 중에도 ready 전 처리를 하지 않음")
	_check(main.is_node_ready() and main.get_viewport() != null, "SA-02 ready 완료 후 Viewport 확보")
	_check(main.offset_top == 14.0 and main.offset_bottom == -8.0, "SA-02 ready 안에서 최초 안전 영역 적용")
	ProjectSettings.set_setting("princess_tycoon/testing/safe_area_insets", Vector2(24, 12))
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(main.offset_top == 24.0 and main.offset_bottom == -12.0, "SA-02 정상 포커스 복귀에서 여백 갱신")
	var engine: RefCounted = main.get("_engine")
	var before := JSON.stringify(engine.call("get_state"))
	root.remove_child(main)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", NOW + 300)
	ProjectSettings.set_setting("princess_tycoon/testing/safe_area_insets", Vector2(30, 16))
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	main.call("_apply_safe_area")
	root.size_changed.emit()
	_check(main.get_viewport() == null, "SA-03 분리 후 Viewport 없음")
	_check(main.offset_top == 24.0 and main.offset_bottom == -12.0, "SA-03 분리 후 알림과 연결된 size_changed 콜백은 여백 변경 없음")
	_check(JSON.stringify(engine.call("get_state")) == before, "SA-03 분리 후 알림은 게임 진행·저장 기준시각 변경 없음")
	root.add_child(main)
	await process_frame
	main.notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	_check(main.offset_top == 30.0 and main.offset_bottom == -16.0, "SA-02 재진입 후 안전 영역 다시 적용")
	var resumed := engine.call("get_state") as Dictionary
	_check(int(resumed.lastSimulatedAt) == NOW + 300 and int(resumed.time.slot) == 0, "SA-02 정상 수동 모드 복귀의 0slot 기준시각 처리 유지")
	before = JSON.stringify(resumed)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", NOW + 600)
	ProjectSettings.set_setting("princess_tycoon/testing/safe_area_insets", Vector2(40, 20))
	main.queue_free()
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	main.call("_apply_safe_area")
	root.size_changed.emit()
	_check(main.offset_top == 30.0 and main.offset_bottom == -16.0, "SA-03 삭제 대기 중 여백 변경 없음")
	_check(JSON.stringify(engine.call("get_state")) == before, "SA-03 삭제 대기 중 게임·저장 처리 없음")
	await process_frame
	ProjectSettings.set_setting("princess_tycoon/testing/safe_area_insets", Vector2.ZERO)
	_cleanup()
	print("[SAFE-AREA-LIFECYCLE] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
