extends SceneTree
const Driver = preload("res://tests/e2e/e2e_driver.gd")
const SAVE := "user://qa_adventure_capture.json"
var viewport_size := Vector2i(390,844)
var out := ""
var capture := false
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--viewport="):
			var parts:=arg.trim_prefix("--viewport=").split("x")
			viewport_size=Vector2i(int(parts[0]),int(parts[1]))
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":capture=true
	call_deferred("_run")
func _run()->void:
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path",SAVE)
	ProjectSettings.set_setting("princess_tycoon/testing/fixed_unix",1_800_000_000)
	var driver:=Driver.new(self,viewport_size,out,capture)
	var main:Control=(load("res://scenes/main.tscn") as PackedScene).instantiate()
	await driver.mount(main)
	main.set("_auto_running",false)
	driver.begin("home-goal",["home-goal"])
	driver.step("new home explains the goal", _find(main, "home_goal") != null and _find(main, "home_goal_action") != null)
	await driver.shot("home-new-goal")
	driver.end()
	var forest_result: Dictionary = {}
	for id in ["ADV_FOREST","ADV_CAVE","ADV_RUINS","ADV_VOLCANO","ADV_RIFT"]:
		var engine:Object=main.get("_engine")
		var fixture:=StateFactory.create(915)
		fixture.unlocks={"stage":7,"announced":7,"tipsSeen":[]}
		fixture.worldTier=5
		fixture.growthPolicy.bannedTags=[]
		fixture.growthPolicy.reserveGold=BigValue.zero()
		for stat in fixture.stats:fixture.stats[stat]=700.0
		engine.call("initialize_from_state",fixture)
		var response:Dictionary=engine.call("run_activity",id,1_800_000_000)
		main.call("_sync_engine_state")
		var result:Dictionary=response.get("result",{})
		if id == "ADV_FOREST":
			forest_result = result.duplicate(true)
		driver.begin(id,["adventure-scene","adventure-trace"])
		driver.step("actual adventure resolved",bool(response.get("ok",false)))
		var before:=JSON.stringify(engine.call("get_state"))
		main.call("_start_adventure_scene",result,false,"")
		await driver.frames(3)
		var playback:RefCounted=main.get("_adventure_playback")
		for step in 8:
			playback.set("elapsed",float(step)*float(playback.call("duration"))/8.0)
			await driver.frames(2)
			await driver.shot(id+"-%02d"%step)
		playback.set("elapsed", 0.0)
		await driver.frames(2)
		var skip: Button = _find(main, "adventure_skip") as Button
		driver.step("skip receives coordinate input", skip != null and await driver.tap(skip))
		await driver.frames(2)
		await driver.shot(id+"-result")
		driver.step("scene never changes rewards or RNG",JSON.stringify(engine.call("get_state"))==before)
		var close: Button = _find(main, "adventure_close") as Button
		driver.step("close receives coordinate input", close != null and await driver.tap(close))
		await driver.frames(2)
		driver.end()
	driver.begin("automatic-home", ["adventure-scene", "adventure-lifecycle"])
	(main.call("_game_config") as Dictionary)["onlineSecondsPerSlot"] = 10000.0
	main.set("_auto_running", true)
	main.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	main.call("_start_adventure_scene", forest_result, true, "")
	await driver.frames(4)
	var compact: Control = main.get("_compact_adventure_view")
	driver.step("automatic result stays inside home", is_instance_valid(compact) and not is_instance_valid(main.get("_adventure_dialog")))
	await driver.shot("home-automatic-adventure")
	var pause := _find(compact, "adventure_pause") as Button
	driver.step("compact scene has an accessible pause", pause != null and await driver.tap(pause))
	var clock: RefCounted = main.get("_adventure_playback")
	var frozen := float(clock.get("elapsed"))
	await driver.frames(20)
	driver.step("pause freezes the same scene", float(clock.get("elapsed")) == frozen)
	driver.step("compact scene resumes", await driver.tap(pause))
	var expand := _find(compact, "adventure_expand") as Button
	driver.step("expand receives coordinate input", expand != null and await driver.tap(expand))
	await driver.frames(3)
	driver.step("expanding preserves the clock", main.get("_adventure_dialog_playback") == clock and float(clock.get("elapsed")) >= frozen)
	var close := _find(main.get("_adventure_dialog"), "adventure_close") as Button
	driver.step("expanded scene closes", close != null and await driver.tap(close))
	driver.end()
	await driver.unmount(main)
	_cleanup()
	quit(driver.finish({"sourceSha":OS.get_environment("SOURCE_SHA") if not OS.get_environment("SOURCE_SHA").is_empty() else "development-uncommitted","fixture":"actual deterministic adventure results"}))
func _cleanup()->void:
	for suffix in ["",".bak",".tmp",".corrupt"]:
		if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))

func _find(node:Node,id:String)->Node:
	if node == null or node.is_queued_for_deletion():return null
	if str(node.get_meta("ui_id",""))==id:return node
	for child in node.get_children():
		var found:=_find(child,id)
		if found!=null:return found
	return null
