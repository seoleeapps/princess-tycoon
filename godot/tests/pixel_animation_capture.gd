extends SceneTree

# 실제 main 화면에 활동 fixture를 넣고 시간으로 재생되는 8프레임+반복 경계를 캡처한다.
# 전체 사용자 여정은 tests/e2e/journey.gd에서 별도로 실행한다.
const Driver := preload("res://tests/e2e/e2e_driver.gd")
const CASES := {
	"book": "EDU_LITERATURE", "magic": "EDU_MAGIC", "ledger": "JOB_FARM",
	"tea": "REST_HOME", "compass": "ADV_FOREST", "flag": "CH_EXAM_ACADEMY",
	"candle": "REST_HOME", "leaves": "JOB_FARM",
}
const SAVE_PATH := "user://qa_pixel_animation_capture.json"
var out := ""
var only := ""
var view_size := Vector2i(390, 844)
var e2e: Driver


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
		if arg.begins_with("--viewport="):
			var parts := arg.trim_prefix("--viewport=").split("x")
			view_size = Vector2i(int(parts[0]), int(parts[1]))
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE_PATH)
	e2e = Driver.new(self, view_size, out, true)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	await e2e.mount(main)
	# fixture는 활동을 완료하지 않는다. 긴 온라인 주기로 같은 활동의 전체 루프를 관찰한다.
	main.set("_auto_running", true)
	for clip: String in CASES:
		if not only.is_empty() and only != clip: continue
		var fixture := (main.get("_state") as Dictionary).duplicate(true)
		fixture["pendingOfflineSlots"] = 0
		fixture["activeTask"] = {"id": CASES[clip], "activityId": CASES[clip], "durationSlots": 1, "remainingSlots": 1, "startedAtSlot": 0}
		var engine: Object = main.get("_engine")
		main.call("_adopt_engine_result", engine.call("initialize_from_state", fixture))
		(main.call("_game_config") as Dictionary)["onlineSecondsPerSlot"] = 10000.0
		main.call("_render_current_page")
		main.call("_refresh_chrome")
		main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
		var player: RefCounted = main.get("_pixel_animation_player")
		player.set("activity_time", 0.0)
		player.set("environment_time", 0.0)
		var ambient := clip in ["candle", "leaves"]
		e2e.begin(clip + "-full-loop", ["home-activity-animation", "home-environment-animation"])
		e2e.expect_equal("selected clip", player.get("environment_clip" if ambient else "activity_clip"), clip)
		for frame_index in 9:
			var expected := frame_index % 8
			var reached := await e2e.wait_for(func() -> bool: return int(player.call("frame", ambient)) == expected, 180)
			e2e.step("reaches frame %d" % frame_index, reached, "time=%s running=%s focused=%s task=%s" % [player.get("activity_time"), player.get("running"), main.get("_application_focused"), (main.get("_state") as Dictionary).get("activeTask")])
			await e2e.shot("%s-%02d" % [clip, frame_index])
			await e2e.frames(1)
		# 좌표 입력이 도구 레이어와 함께 작동하는지 같은 실제 화면에서 확인한다.
		var pause: Button = main.get("_pause_button")
		e2e.step("pause input passes decoration", await e2e.tap(pause))
		e2e.expect_equal("paused", bool(main.get("_auto_running")), false)
		var frozen := float(player.get("activity_time"))
		await e2e.frames(20)
		e2e.expect_equal("pause freezes clock", float(player.get("activity_time")), frozen)
		e2e.step("resume input passes decoration", await e2e.tap(pause))
		e2e.expect_equal("resumed", bool(main.get("_auto_running")), true)
		e2e.end()
	await e2e.unmount(main)
	_cleanup()
	quit(e2e.finish({"sourceSha": OS.get_environment("SOURCE_SHA"), "fixture": "activeTask descriptor; onlineSecondsPerSlot=10000", "viewport": str(view_size)}))


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
