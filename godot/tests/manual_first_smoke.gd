extends SceneTree

const SAVE := "user://qa_manual_first.json"
const NOW := 1_800_000_000
var checks := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var fresh := StateFactory.create(927)
	_check(not bool(fresh.settings.autoRun), "MF-01 신규 자동 OFF")
	for enabled: bool in [true, false]:
		var old := fresh.duplicate(true)
		old.settings.autoRun = enabled
		_check(StateFactory.ensure_v2_shape(old).settings.autoRun == enabled, "MF-01 기존 자동 선택 보존 %s" % enabled)
	var legacy := fresh.duplicate(true)
	legacy.settings.erase("autoRun")
	_check(bool(StateFactory.ensure_v2_shape(legacy).settings.autoRun), "MF-01 키 없는 구형 저장의 종전 기본 보존")
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", NOW)
	root.size = Vector2i(390, 844)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var slot := int((main.get("_state") as Dictionary).time.slot)
	main.call("_process", 6.0)
	_check(not bool(main.get("_auto_running")) and int((main.get("_state") as Dictionary).time.slot) == slot, "MF-01 초기 대기 중 성장하지 않음")
	_check(not (_find(main, "offline_open") as Control).visible, "MF-03 미정산 없으면 홈 버튼 숨김")
	_check(not (_find(main, "pause") as Control).visible, "MF-02 학습 전 홈에서 자동 시작을 권하지 않음")
	main.call("_complete_current_activity")
	_check(int((main.get("_state") as Dictionary).time.slot) > slot and not bool(main.get("_auto_running")), "MF-01 수동 활동은 자동을 켜지 않고 진행")
	var ready := StateFactory.create(927)
	ready.settings.autoRun = false
	ready.settings.guidanceSeen = ["intro", "first_direction"]
	ready.lifetimeStats.activities = 8
	ready.time.slot = 8
	ready.unlocks = {"stage": 3, "announced": 3, "tipsSeen": ["plan"]}
	ready.lastSimulatedAt = NOW - 600
	var engine: RefCounted = main.get("_engine")
	engine.call("initialize_from_state", ready)
	main.call("_sync_engine_state")
	main.set("_auto_running", false)
	main.call("_show_tab", "home")
	_check(_find(main, "open_plan") == null, "MF-04 홈 성장 방향 바로가기 제거")
	var goal: Dictionary = main.call("_home_goal_description")
	_check(goal.action == "auto" and goal.action_label == "자동 진행 켜기", "MF-02 체험·방향 선택 뒤 자동 권유")
	main.call("_open_goal_target", "auto")
	main.call("_open_goal_target", "auto")
	_check(bool(main.get("_auto_running")) and bool((engine.call("get_state") as Dictionary).settings.autoRun), "MF-02 명시적 자동 시작은 반복 입력에도 ON")
	_check(int((engine.call("get_state") as Dictionary).lastSimulatedAt) == NOW, "MF-02 학습 중 대기 시간은 방치 보상에 넣지 않음")
	main.call("_toggle_auto")
	goal = main.call("_home_goal_description")
	_check(not bool(main.get("_auto_running")) and goal.action != "auto", "MF-02 시작 경험 후 정지하면 첫 권유 반복 안 함")
	main.call("_toggle_setting", true, "autoRun")
	_check(bool(main.get("_auto_running")) and (main.get("_state") as Dictionary).settings.guidanceSeen.has("auto_started"), "MF-02 설정의 명시적 시작도 같은 안내 기록")
	var pending := engine.call("get_state") as Dictionary
	pending.settings.autoRun = true
	pending.lastSimulatedAt = NOW - 120
	engine.call("initialize_from_state", pending)
	main.call("_sync_engine_state")
	(main.get("_state") as Dictionary)["pendingOfflineSlots"] = 2
	(main.get("_state") as Dictionary)["lastOfflineSummary"] = {"slotsAdvanced": 10}
	main.call("_refresh_chrome")
	var settle := _find(main, "offline_open") as Button
	_check(settle.visible and settle.text == "정산하기", "MF-03 실제 미정산이 있을 때만 정산 CTA")
	main.call("_toggle_auto")
	_check(bool(main.get("_auto_running")) and int((main.get("_state") as Dictionary).pendingOfflineSlots) == 2, "MF-03 정산 대기 중 자동 변경으로 결과 잃지 않음")
	main.call("_toggle_setting", false, "autoRun")
	_check(bool((engine.call("get_state") as Dictionary).settings.autoRun), "MF-03 설정에서도 미정산 중 자동 변경을 막음")
	main.call("_open_sheet", "offline")
	_check(_has_label(main, "정산 가능 2회") and not _has_label(main, "오프라인 성장 10회 완료"), "MF-03 과거 정산보다 현재 미정산 우선")
	main.call("_collect_offline")
	_check(not (_find(main, "offline_open") as Control).visible and int((main.get("_state") as Dictionary).pendingOfflineSlots) == 0, "MF-03 정산 후 홈 버튼 숨김")
	var settled_slot := int((engine.call("get_state") as Dictionary).time.slot)
	var summary := JSON.stringify((main.get("_state") as Dictionary).lastOfflineSummary)
	main.call("_collect_offline")
	_check(int((engine.call("get_state") as Dictionary).time.slot) == settled_slot and JSON.stringify((main.get("_state") as Dictionary).lastOfflineSummary) == summary, "MF-03 반복 정산은 중복 성장·결과 덮어쓰기 없음")
	main.set("_activity_elapsed", 2.5)
	(main.get("_activity_progress") as Control).set("value", 50.0)
	main.call("_create_trainee", "balanced")
	_check(not bool(main.get("_auto_running")) and not bool((engine.call("get_state") as Dictionary).settings.autoRun) and float((main.get("_activity_progress") as Control).get("value")) == 0.0, "MF-01 새 수련생도 OFF와 초기 진행률")
	main.call("_reset_game")
	_check(not bool(main.get("_auto_running")) and not bool((engine.call("get_state") as Dictionary).settings.autoRun), "MF-01 초기화도 OFF")
	main.queue_free()
	await process_frame
	_cleanup()
	print("[MANUAL-FIRST] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _find(node: Node, id: String) -> Node:
	if str(node.get_meta("ui_id", "")) == id:
		return node
	for child: Node in node.get_children():
		var found := _find(child, id)
		if found != null:
			return found
	return null

func _has_label(node: Node, text: String) -> bool:
	if node is Label and node.is_visible_in_tree() and node.text == text:
		return true
	for child: Node in node.get_children():
		if _has_label(child, text): return true
	return false

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
