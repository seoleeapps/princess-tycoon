extends SceneTree

const SAVE := "user://qa_clarity_runtime.json"
var failed := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var fresh := StateFactory.create(91)
	_check((fresh.settings as Dictionary).get("guidanceSeen") is Array, "CL-03 새 저장에 안내 완료 목록")
	var old := fresh.duplicate(true)
	(old.settings as Dictionary).erase("guidanceSeen")
	var migrated := StateFactory.ensure_v2_shape(old)
	var seen: Array = (migrated.settings as Dictionary).get("guidanceSeen", []) as Array
	_check(seen.has("intro") and seen.has("first_direction"), "CL-03 기존 저장에 강제 첫 안내를 띄우지 않음")
	var engine := GameEngine.new()
	engine.initialize(91)
	var before := JSON.stringify(engine.get_state())
	var has_preview := engine.has_method("career_goal_preview")
	_check(has_preview, "CL-02 현재 진로 조건을 읽기 전용으로 조회")
	if has_preview:
		var preview: Array = engine.call("career_goal_preview") as Array
		_check(preview.size() == 38, "CL-02 진로 38개 모두 현재 조건으로 평가")
		_check(JSON.stringify(engine.get_state()) == before, "CL-02 진로 미리보기는 보상·난수·상태를 바꾸지 않음")
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", 1_800_000_000)
	_cleanup()
	root.size = Vector2i(390, 844)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	_check(_find(main, "home_goal") != null, "CL-01 첫 홈에 장기 목표")
	_check(_find(main, "home_goal_action") != null, "CL-01 첫 홈에 가능한 다음 행동")
	_check(_find(main, "run_auto_once") is Button and (_find(main, "run_auto_once") as Button).text == "지금 활동 마치기", "CL-01 수동 즉시 실행의 의미를 구분")
	main.call("_open_sheet", "help")
	await process_frame
	_check(_find(main, "help_loop") != null, "CL-01 메뉴에서 다시 보는 실제 육성 흐름")
	main.queue_free()
	await process_frame
	_cleanup()
	print("[CLARITY-RUNTIME] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _find(node: Node, id: String) -> Node:
	if str(node.get_meta("ui_id", "")) == id:
		return node
	for child in node.get_children():
		var found := _find(child, id)
		if found != null:
			return found
	return null

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
