extends SceneTree

const SAVE := "user://qa_adventure_view.json"
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix", 1_800_000_000)
	_cleanup()
	root.size = Vector2i(390, 844)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set("_auto_running", false)
	var engine: Object = main.get("_engine")
	var state: Dictionary = engine.call("get_state")
	state.unlocks.stage=7
	for key in state.stats:
		state.stats[key]=700.0
	state.growthPolicy.bannedTags=[]
	engine.call("initialize_from_state",state)
	var result: Dictionary = engine.call("run_activity","ADV_FOREST",1_800_000_000)
	var activity: Dictionary = result.get("result",{})
	_check(not activity.is_empty(),"실제 모험 결과 생성")
	main.call("_sync_engine_state")
	var before := JSON.stringify(engine.call("get_state"))
	main.call("_start_adventure_scene",activity,false,"")
	await process_frame
	await process_frame
	_check(_find(main,"adventure_scene")!=null,"실제 결과로 A 장면 열림")
	var playback: RefCounted = main.get("_adventure_playback")
	playback.call("skip")
	await process_frame
	_check((_find(main,"adventure_event") as Label).text.contains("탐험 완료"),"건너뛰기는 실제 결과 표시")
	_check(not (_find(main,"adventure_rewards") as Label).text.contains("itemId"),"전리품은 내부 객체 대신 이름과 수량으로 표시")
	main.call("_handle_back")
	await process_frame
	_check(not is_instance_valid(main.get("_adventure_dialog")),"뒤로 가기는 모험 장면부터 닫음")
	_check(JSON.stringify(engine.call("get_state"))==before,"재생·건너뛰기·닫기는 추가 보상·난수를 만들지 않음")
	main.call("_start_adventure_scene",activity,false,"")
	await process_frame
	var manual_clock: RefCounted = main.get("_adventure_dialog_playback")
	var next_response: Dictionary = engine.call("run_activity","ADV_FOREST",1_800_000_000)
	main.call("_sync_engine_state")
	var second: Dictionary = next_response.get("result", {})
	_check(not second.is_empty(), "이어지는 자동 결과도 실제 판정 사용")
	main.call("_start_adventure_scene",second,true,"")
	await process_frame
	_check(main.get("_adventure_dialog_playback") == manual_clock and main.get("_adventure_playback") != manual_clock, "자동 결과가 보고 있는 수동 장면의 시계를 덮어쓰지 않음")
	main.call("_close_adventure")
	await process_frame
	var after_second := JSON.stringify(engine.call("get_state"))
	main.call("_remember_recent_adventure", [activity, {"kind":"rest"}, second])
	_check((main.get("_adventure_result") as Dictionary).get("slot") == second.get("slot") and bool((main.get("_adventure_playback") as RefCounted).call("current").get("finished",false)), "최근 원정 하나만 보관하고 오프라인 요약을 가로채지 않음")
	_check(JSON.stringify(engine.call("get_state"))==after_second, "최근 장면 보관도 저장·보상을 바꾸지 않음")
	main.call("_clear_adventure_presentation")
	_check((main.get("_adventure_result") as Dictionary).is_empty(), "새 수련생을 만들 때 이전 원정 장면 정리")
	var save_fixture := engine.call("get_state") as Dictionary
	save_fixture.meters.energy = 100.0
	save_fixture.meters.stress = 0.0
	save_fixture.forceRest = false
	save_fixture.time.slot = 0
	save_fixture.activeTask = null
	save_fixture.activityQueue = []
	engine.call("initialize_from_state", save_fixture)
	main.call("_sync_engine_state")
	main.call("_start_adventure_scene", activity, false, "")
	(main.get("_state") as Dictionary)["pendingOfflineSlots"] = 1
	var before_pending: Dictionary = engine.call("get_state")
	main.call("_run_activity", "ADV_FOREST")
	await process_frame
	_check(not is_instance_valid(main.get("_adventure_dialog")) and bool(main.call("_find_open_sheet", "offline")), "오프라인 정산 대기는 모험 장면보다 먼저 안내")
	var after_pending: Dictionary = engine.call("get_state")
	# 시트를 열며 해금 알림 확인 표시는 바뀔 수 있다. 활동 결과와 해금 단계는 바뀌지 않아야 한다.
	var stage_before := int((before_pending.get("unlocks", {}) as Dictionary).get("stage", 0))
	var stage_after := int((after_pending.get("unlocks", {}) as Dictionary).get("stage", 0))
	before_pending.erase("unlocks")
	after_pending.erase("unlocks")
	_check(stage_before == stage_after and JSON.stringify(after_pending) == JSON.stringify(before_pending), "정산 대기 중 원정을 중복 실행하지 않음")
	(main.get("_state") as Dictionary)["pendingOfflineSlots"] = 0
	main.call("_close_sheet")
	await process_frame
	engine.set("_save_path", "   ")
	main.call("_run_activity", "ADV_FOREST")
	await process_frame
	_check(not is_instance_valid(main.get("_adventure_dialog")), "저장 실패 때 성공 장면을 열지 않음")
	_check((main.get("_toast_label") as Label).text.contains("저장"), "저장 실패와 다시 저장할 방법 표시")
	engine.set("_save_path", SAVE)
	var unsaved := engine.call("get_state") as Dictionary
	_check(bool(main.call("_persist_silently")) and int((engine.call("get_state") as Dictionary).get("rngCounter", -1)) == int(unsaved.get("rngCounter", -2)), "저장 재시도는 활동을 다시 판정하지 않음")
	main.call("_remember_recent_adventure", [activity])
	main.call("_continue_game")
	_check((main.get("_adventure_result") as Dictionary).is_empty(), "저장 복원 때 이전 메모리 장면을 섞지 않음")
	main.queue_free()
	await process_frame
	_cleanup()
	print("[ADVENTURE-VIEW] checks=%d failed=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
func _find(node:Node,id:String)->Node:
	if str(node.get_meta("ui_id",""))==id:return node
	for child in node.get_children():
		var found:=_find(child,id)
		if found!=null:return found
	return null
func _cleanup()->void:
	for suffix in ["",".bak",".tmp",".corrupt"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
func _check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("[%s] %s"%["PASS" if ok else "FAIL",label])
