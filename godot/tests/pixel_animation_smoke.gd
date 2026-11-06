extends SceneTree

const PLAYER_PATH := "res://src/ui/pixel/pixel_animation_player.gd"
const SAVE_PATH := "user://qa_pixel_animation_save.json"
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(PLAYER_PATH):
		_check(false, "PA-01 활동 애니메이션 재생기 존재")
		_finish()
		return
	var script := load(PLAYER_PATH) as Script
	var player: RefCounted = script.new()
	for entry: Array in [["education", [], "book"], ["education", ["magic"], "magic"], ["job", [], "ledger"], ["rest", [], "tea"], ["adventure", [], "compass"], ["challenge", ["exam"], "flag"], ["exam", [], "flag"], ["sport", [], "flag"], ["contest", [], "flag"], ["league", [], "flag"]]:
		player.call("set_activity_context", {"id": "test", "kind": entry[0], "tags": entry[1]}, true)
		_check(player.get("activity_clip") == entry[2], "PA-01 kind=%s tags=%s" % [entry[0], entry[1]])
	player.call("set_activity_context", {}, true)
	_check(player.get("activity_clip") == "", "PA-01 진행 활동 없음은 도구 없음")
	player.call("set_activity_context", {"id": "unknown", "kind": "unknown"}, true)
	_check(player.get("activity_clip") == "", "PA-01 알 수 없는 종류는 도구 없음")
	for entry: Array in [["academy", "candle"], ["library", "candle"], ["city", "leaves"], ["forest", "leaves"], ["arena", ""]]:
		player.call("set_environment", entry[0])
		_check(player.get("environment_clip") == entry[1], "PA-01 환경 %s" % entry[0])
	player.call("set_environment", "library")
	player.call("set_activity_context", {"id": "A", "kind": "education"}, true)
	player.call("advance", 0.51)
	_check(player.call("frame", false) == 3 and player.call("frame", true) == 2, "PA-02 도구 6fps 환경 4fps")
	player.call("set_activity_context", {"id": "A", "kind": "education"}, true)
	_check(player.call("frame", false) == 3, "PA-02 같은 활동 context 갱신은 시간 보존")
	player.call("set_activity_context", {"id": "A", "kind": "education"}, false)
	player.call("advance", 10.0)
	_check(player.call("frame", false) == 3 and player.call("frame", true) == 2, "PA-02 정지 중 두 타임라인 보존")
	player.call("set_activity_context", {"id": "A", "kind": "education"}, true)
	player.set("reduced_motion", true)
	var before := float(player.get("activity_time"))
	player.call("advance", 10.0)
	_check(player.call("frame", false) == 0 and is_equal_approx(float(player.get("activity_time")), before), "PA-02 모션 줄이기는 참조·시간 고정")
	player.set("reduced_motion", false)
	_check(player.call("frame", false) == 3, "PA-02 모션 재개는 보존한 위치")
	player.call("set_activity_context", {"id": "B", "kind": "education"}, true)
	_check(player.call("frame", false) == 0, "PA-02 같은 종류 다른 활동 전환은 도구 초기화")
	player.call("advance", 80.25)
	_check(player.call("frame", false) == 1, "PA-02 긴 delta도 8프레임 범위 반복")
	_check(player.call("texture_for", "missing", false) == null, "PA-03 누락 에셋은 오류 없이 숨김")
	_check(player.call("texture_for", "references/book", false) == null, "PA-03 크기가 다른 에셋은 오류 없이 숨김")
	for clip: String in ["book", "magic", "ledger", "tea", "compass", "flag", "candle", "leaves"]:
		var texture: Texture2D = player.call("texture_for", clip, false)
		var reference: Texture2D = player.call("texture_for", clip, true)
		_check(texture != null and texture.get_size() == Vector2(512, 64) and reference != null and reference.get_size() == Vector2(64, 64), "PA-03 %s 시트와 참조 크기" % clip)
		_check(texture == player.call("texture_for", clip, false), "PA-03 %s 텍스처 캐시" % clip)
		if texture != null:
			var image := texture.get_image()
			var has_transparent_corner := image.get_pixel(0, 0).a == 0.0
			_check(has_transparent_corner and image.get_used_rect().has_area(), "PA-03 %s 투명 배경과 비어 있지 않은 그림" % clip)
	await _check_main()
	_finish()


func _check_main() -> void:
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE_PATH)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var state: Dictionary = main.get("_state")
	state["activeTask"] = {"activityId": "EDU_MAGIC"}
	state["pendingOfflineSlots"] = 0
	main.set("_auto_running", true)
	main.call("_refresh_chrome")
	var player: RefCounted = main.get("_pixel_animation_player")
	main.call("_process", 0.51)
	_check(player.get("activity_clip") == "magic", "PA-01 실제 activeTask descriptor의 magic 태그 사용")
	_check(player.get("running") == true, "PA-02 홈의 활성 활동은 재생")
	var time := float(player.get("activity_time"))
	main.call("_render_current_page")
	_check(is_equal_approx(float(player.get("activity_time")), time), "PA-02 홈 재생성은 시간 보존")
	state["activeTask"] = {"activityId": "JOB_FARM"}
	main.call("_render_current_page")
	main.call("_process", 0.31)
	var ambient_time := float(player.get("environment_time"))
	main.call("_render_current_page")
	_check(is_equal_approx(float(player.get("environment_time")), ambient_time), "PA-02 도시 홈 재생성은 잎사귀 시간 보존")
	time = float(player.get("activity_time"))
	main.call("_show_tab", "activity")
	main.call("_process", 0.2)
	_check(is_equal_approx(float(player.get("activity_time")), time), "PA-02 홈 이탈은 정지")
	main.call("_show_tab", "home")
	main.call("_process", 0.2)
	_check(float(player.get("activity_time")) > time, "PA-02 홈 재진입은 이어 재생")
	for gate: String in ["pause", "offline", "inactive"]:
		time = float(player.get("activity_time"))
		if gate == "pause": main.set("_auto_running", false)
		if gate == "offline": state["pendingOfflineSlots"] = 1
		if gate == "inactive": main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		main.call("_process", 0.2)
		_check(is_equal_approx(float(player.get("activity_time")), time), "PA-02 %s gate 정지" % gate)
		main.set("_auto_running", true)
		state["pendingOfflineSlots"] = 0
		main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	var original_rng: Variant = state.get("rngCounter")
	var original_seed: Variant = state.get("seed")
	main.call("_process", 0.2)
	_check(state.get("rngCounter") == original_rng and state.get("seed") == original_seed, "PA-04 재생은 저장 seed·rngCounter를 소비하지 않음")
	main.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	main.call("_process", 0.2)
	_check(not bool(player.get("running")), "PA-02 앱 pause는 focus in만으로 재개하지 않음")
	main.notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	main.call("_process", 0.01)
	_check(bool(player.get("running")), "PA-02 앱 resume 뒤 재생 가능")
	state = main.get("_state") as Dictionary
	state["activeTask"] = null
	main.call("_process", 0.01)
	_check(player.get("activity_clip") == "", "PA-01 null activeTask는 도구 숨김")
	var avatar: Control = main.get("_home_avatar")
	_check(avatar.mouse_filter == Control.MOUSE_FILTER_IGNORE and avatar.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "PA-04 입력 무시·nearest 필터")
	var original: Image = avatar.call("trainee_image")
	avatar.call("set_activity_context", {"id": "job", "kind": "job"}, true)
	_check((avatar.call("trainee_image") as Image).get_data() == original.get_data(), "PA-04 활동 도구가 장비·성장색 합성 결과를 바꾸지 않음")
	_check(not state.has("pixelAnimation") and not state.has("animationTime"), "PA-04 재생 시간은 게임 저장에 추가하지 않음")
	main.queue_free()
	await process_frame
	_cleanup()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


func _finish() -> void:
	print("[PIXEL-ANIMATION] %s checks=%d failed=%d" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
