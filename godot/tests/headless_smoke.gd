extends SceneTree

const EXPECTED_SCREENS: Array[String] = [
	"home", "plan", "activity", "growth", "record",
	"world", "shop", "settings", "offline", "event", "profile", "continue",
]
const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const SAVE_PATH := "user://qa_headless_smoke_save.json"

var _failures: Array[String] = []
var _passes: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[SMOKE] Main scene headless interaction")
	_prepare_test_save()
	root.size = Vector2i(390, 844)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main.tscn 로드")
	if packed == null:
		_finish()
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_check(is_instance_valid(main) and main.is_inside_tree(), "main scene 인스턴스 진입")
	_check(main is Control and (main as Control).size.x > 0.0 and (main as Control).size.y > 0.0, "main root 유효 bounds")
	_check(str(main.get_meta("screen_id", "")) == "home", "초기 홈 화면")

	var raw_screens: Variant = main.get_meta("available_screen_ids", PackedStringArray())
	var available: PackedStringArray = PackedStringArray(raw_screens) if raw_screens is PackedStringArray or raw_screens is Array else PackedStringArray()
	_check(available.size() == 12, "AC-UI-02 기능 경로 12개")
	for screen_id: String in EXPECTED_SCREENS:
		_check(available.has(screen_id), "기능 경로 노출: %s" % screen_id)

	var ctas: Array[Node] = _descendant_group_nodes(main, "critical_cta")
	_check(ctas.size() >= 6, "critical_cta 그룹 노출")
	var touch_targets_ok: bool = true
	for cta: Node in ctas:
		if cta is Control and (cta as Control).is_visible_in_tree():
			var control: Control = cta as Control
			if control.size.x < 44.0 or control.size.y < 44.0:
				touch_targets_ok = false
	_check(touch_targets_ok, "AC-UI-04 critical CTA 44x44 이상")

	var engine_value: Variant = main.get("_engine")
	var engine: Object = engine_value as Object
	_check(engine != null and engine.has_method("get_state"), "MainScreen GameEngine 연결")
	if engine != null and engine.has_method("get_state"):
		var before: Dictionary = engine.call("get_state") as Dictionary
		var before_slot: int = int((before.get("time", {}) as Dictionary).get("slot", -1))
		var decision: Dictionary = engine.call("preview_next_activity") as Dictionary
		_check(not str(decision.get("activityId", "")).is_empty(), "GameEngine 다음 활동 상호작용")
		var step: Dictionary = engine.call("advance_slots", 1) as Dictionary
		var after: Dictionary = engine.call("get_state") as Dictionary
		_check(int(step.get("slotsAdvanced", 0)) == 1, "GameEngine 1 slot 실행")
		_check(int((after.get("time", {}) as Dictionary).get("slot", -1)) == before_slot + 1, "GameEngine 상태 진행")
		_check(bool((engine.call("validate_state") as Dictionary).get("ok", false)), "GameEngine 상호작용 후 상태 유효")

	# 새 게임은 1단계라 계획 탭과 월드 시트가 열리지 않는다(AC-UNLOCK-01).
	main.call("_show_tab", "plan")
	await process_frame
	_check(str(main.get_meta("screen_id", "")) == "home", "1단계에서 잠긴 계획 탭은 홈으로")
	main.call("_open_sheet", "world")
	await process_frame
	_check(_find_screen_node(main, "world") == null, "1단계에서 잠긴 월드 시트는 열리지 않음")
	# AC-UNLOCK-12: 아직 열리지 않은 개념(위험, 계약, 프리셋)은 이유 줄에 쓰지 않는다.
	_check(not bool(main.call("_reason_concept_open", "위험 부담")) and not bool(main.call("_reason_concept_open", "고정 계약")) and bool(main.call("_reason_concept_open", "성장 방향")), "1단계 이유 줄은 열린 개념만")
	_check(not str(main.call("_planner_reason")).contains("위험") and not str(main.call("_planner_reason")).contains("계약"), "1단계 현재 활동 이유에 잠긴 개념 없음")
	# 단계가 열리기 전 결정에 남은 해금 잠금은 이미 열린 활동의 잠금 이유로 보이지 않는다.
	var stale_state: Dictionary = main.get("_state") as Dictionary
	stale_state["lastPlannerDecision"] = {"rejected": {"EDU_PAINTING": "해금 단계 잠금"}}
	(stale_state["unlocks"] as Dictionary)["stage"] = 4
	_check(str(main.call("_activity_lock_reason", "EDU_PAINTING")) == "", "열린 활동에 지난 결정의 해금 잠금 문구 없음")
	(stale_state["unlocks"] as Dictionary)["stage"] = 1
	_check(str(main.call("_activity_lock_reason", "EDU_PAINTING")) == "아직 열리지 않았어요", "열리지 않은 활동은 쉬운 잠금 문구")
	# 직전 온라인 새로 열림 알림이 남아 있어도 오프라인 정산 알림에는 붙지 않는다.
	main.set("_unlock_notice_text", "새로 열림 · 아르바이트 3종")
	main.set("_unlock_notice_until", Time.get_ticks_msec() + 5000)
	main.call("_collect_offline")
	await process_frame
	var settle_toast: Label = main.get("_toast_label") as Label
	_check(settle_toast != null and not settle_toast.text.replace("\n", " ").contains("새로 열림"), "오프라인 정산 알림에 직전 새로 열림 문구 없음")
	main.call("_close_sheet")
	await process_frame
	# 기능 경로 도달(AC-UI-02)은 모든 단계를 연 뒤 확인한다.
	if engine != null and engine.has_method("initialize_from_state"):
		var opened: Dictionary = engine.call("get_state") as Dictionary
		opened["unlocks"] = {"stage": 7, "announced": 7, "tipsSeen": []}
		main.call("_adopt_engine_result", engine.call("initialize_from_state", opened))
		main.call("_refresh_chrome")
		await process_frame
	for tab_id: String in ["home", "plan", "activity", "growth", "record"]:
		main.call("_show_tab", tab_id)
		await process_frame
		await process_frame
		_check(str(main.get_meta("screen_id", "")) == tab_id, "탭 도달: %s" % tab_id)

	for sheet_id: String in ["world", "shop", "settings", "offline", "event", "profile", "continue"]:
		main.call("_open_sheet", sheet_id)
		await process_frame
		await process_frame
		_check(_find_screen_node(main, sheet_id) != null, "보조 화면 도달: %s" % sheet_id)
		main.call("_close_sheet")
		await process_frame

	await _check_copy_and_rows(main)
	await _check_manual_expedition(main)
	main.queue_free()
	await process_frame
	_finish()


# 잠금 이유·거절 문구와 활동 행 표시(이슈 #9·#11). 모든 단계를 연 상태에서 시작한다.
func _check_copy_and_rows(main: Node) -> void:
	var state: Dictionary = main.get("_state") as Dictionary
	var unlocks: Dictionary = state["unlocks"] as Dictionary
	var big: Dictionary = state["bigValues"] as Dictionary
	var reserve := float(main.call("_reserve_gold_number"))
	state["worldTier"] = 1
	# 최소 보유금은 7단계 전에는 보이지 않으므로 얼마를 더 모으면 되는지로 알린다.
	unlocks["stage"] = 6
	big["gold"] = BigValue.from_number(368)
	state["lastPlannerDecision"] = {"rejected": {"EDU_LITERATURE": "최소 보유금 위반"}}
	var hidden_reserve := str(main.call("_activity_lock_reason", "EDU_LITERATURE"))
	_check(hidden_reserve == "골드 %dG 더 필요" % int(150.0 + reserve - 368.0), "숨은 최소 보유금은 더 모을 골드로 안내 [%s]" % hidden_reserve)
	unlocks["stage"] = 7
	_check(str(main.call("_activity_lock_reason", "EDU_LITERATURE")) == "최소 보유금 아래로 내려가요", "7단계부터는 최소 보유금 규칙으로 안내")
	# 비용 부족도 실행에 필요한 최소 보유금까지 합쳐 알린다(수동 1회도 보유금 규칙을 따른다).
	big["gold"] = BigValue.from_number(50)
	state["lastPlannerDecision"] = {"rejected": {"EDU_LITERATURE": "비용 지불 불가"}}
	var cost_short := str(main.call("_activity_lock_reason", "EDU_LITERATURE"))
	_check(cost_short == "골드 %dG 더 필요" % int(150.0 + reserve - 50.0), "비용 부족은 보유금까지 합쳐 모자란 골드로 안내 [%s]" % cost_short)
	# 결정 뒤 골드가 늘어 이미 풀린 골드 거절은 잠금 이유로 쓰지 않는다.
	big["gold"] = BigValue.from_number(5000)
	state["lastPlannerDecision"] = {"rejected": {"EDU_LITERATURE": "최소 보유금 위반"}}
	_check(str(main.call("_activity_lock_reason", "EDU_LITERATURE")) == "", "결정 뒤 골드가 늘면 지난 골드 거절을 쓰지 않음")
	# 수동 1회가 앞 활동 뒤 규칙에 밀리면 엔진 원문 대신 밀린 이유를 보여 준다.
	state["lastPlannerDecision"] = {"rejected": {"EDU_LITERATURE": "회복 활동 강제"}}
	var pushed_back := str(main.call("_friendly_rejection", "선행 활동 후 실행 조건을 충족하지 못함", "EDU_LITERATURE"))
	_check(pushed_back == "지금은 회복이 먼저예요", "앞 활동 뒤 밀린 수동 1회는 밀린 이유로 안내 [%s]" % pushed_back)
	state["lastPlannerDecision"] = {"rejected": {}}
	var pushed_generic := str(main.call("_friendly_rejection", "선행 활동 후 실행 조건을 충족하지 못함", "EDU_LITERATURE"))
	_check(not pushed_generic.is_empty() and not pushed_generic.contains("선행 활동 후"), "밀린 이유가 없어도 엔진 원문을 쓰지 않음 [%s]" % pushed_generic)
	# 시험과 겹쳐 잠긴 활동은 실제로 고를 수 있는 날을 알린다. 모든 시험이 열려 있으면 긴 활동은 뒤 시험에도 걸린다.
	var stats: Dictionary = state["stats"] as Dictionary
	for stat_key: String in ["stamina", "combat", "magic", "dance", "art", "communication", "cooking", "intelligence"]:
		stats[stat_key] = 400.0
	state["worldTier"] = 6
	(state["time"] as Dictionary)["slot"] = 5
	state["lastPlannerDecision"] = {"rejected": {"REST_RESORT": "예정 도전 우선: 7번 슬롯", "EDU_LITERATURE": "예정 도전 우선: 7번 슬롯"}}
	var resort_reason := str(main.call("_activity_lock_reason", "REST_RESORT"))
	_check(resort_reason == "다음 시즌 1일째부터", "긴 활동의 시험 겹침은 실제로 풀리는 날 [%s]" % resort_reason)
	_check(str(main.call("_activity_lock_reason", "EDU_LITERATURE")) == "", "이미 풀린 시험 겹침은 잠금 이유로 쓰지 않음")
	(state["time"] as Dictionary)["slot"] = 3
	state["lastPlannerDecision"] = {"rejected": {"EDU_LITERATURE": "예정 도전 우선: 4번 슬롯"}}
	var study_reason := str(main.call("_activity_lock_reason", "EDU_LITERATURE"))
	_check(study_reason == "6일째부터 열려요", "짧은 활동의 시험 겹침은 시험이 끝난 날 [%s]" % study_reason)
	(state["time"] as Dictionary)["slot"] = 5
	state["lastPlannerDecision"] = {"rejected": {"REST_RESORT": "예정 도전 우선: 7번 슬롯"}}
	main.set("_activity_filter", "rest")
	main.call("_show_tab", "activity")
	await process_frame
	await process_frame
	var overlap_line := _row_label(main, "REST_RESORT", "잠금 · ")
	_check(overlap_line != null and _text_fits(overlap_line), "시험 겹침 잠금 줄이 활동 행 안에 들어감 [%s]" % ("" if overlap_line == null else overlap_line.text))
	# 진행 중인 시험 행은 잠금이 아니라 진행 중(남은 날)으로 보인다. 행의 비용은 세계 티어를 반영한 실제 비용이다.
	state["activeTask"] = {"id": "CH_EXAM_ACADEMY", "activityId": "CH_EXAM_ACADEMY", "remainingSlots": 2, "durationSlots": 2, "worldTier": 6, "paidCost": BigValue.zero()}
	main.call("_select_activity_filter", "education")
	await process_frame
	await process_frame
	var cost_line := _row_label(main, "EDU_ETIQUETTE", "-")
	var expected_cost := "-%s" % str(main.call("_format_number", 110.0 * pow(1.11, 5.0)))
	_check(cost_line != null and cost_line.text == expected_cost, "활동 행 비용은 세계 티어 비용 [%s / %s]" % ["" if cost_line == null else cost_line.text, expected_cost])
	main.call("_select_activity_filter", "challenge")
	await process_frame
	await process_frame
	var busy_line := _row_label(main, "CH_EXAM_ACADEMY", "진행 중")
	var busy_locked := _row_label(main, "CH_EXAM_ACADEMY", "잠금")
	_check(busy_line != null and busy_line.text == "진행 중 · 2일 남음" and busy_locked == null and _text_fits(busy_line) and busy_line.get_theme_color("font_color") != PixelTokens.NEGATIVE, "진행 중인 시험 행은 잠금 대신 남은 날 [%s]" % ("" if busy_line == null else busy_line.text))
	main.set("_activity_filter", "education")
	# 월드 시트의 진행 중 시험 카드도 잠금 아이콘·흐린 제목을 쓰지 않는다.
	main.call("_open_sheet", "world")
	await process_frame
	await process_frame
	var exam_name := str(main.call("_activity_name_by_id", "CH_EXAM_ACADEMY"))
	var world_title: Label = null
	var world_busy: Label = null
	var world_sheet := _find_screen_node(main, "world")
	if world_sheet != null:
		for raw_label: Node in world_sheet.find_children("*", "Label", true, false):
			if (raw_label as Label).text == exam_name:
				world_title = raw_label as Label
			elif (raw_label as Label).text == "진행 중 · 2일 남음":
				world_busy = raw_label as Label
	_check(world_busy != null and world_title != null and world_title.get_theme_color("font_color") == PixelTokens.INK, "월드 시트의 진행 중 시험 카드는 진행 중 표시와 본문색 제목")
	main.call("_close_sheet")
	await process_frame
	state["activeTask"] = null
	# 가까운 진로의 부족 조건 줄은 띄어쓰기에서만 줄을 바꾼다("누적 활 / 동" 방지).
	var near_source := "부족 · 절제 107/190, 누적 활동 91/150, 세계 티어 1/2, 무용 12/80"
	state["seasonHistory"] = [{"year": 1, "season": 1, "renownGained": 10, "policyFit": 0.5, "titles": [], "nearTitles": [{"id": "END_SCHOLAR", "name": "왕립 연구자", "progress": 0.5, "missing": ["절제 107/190", "누적 활동 91/150", "세계 티어 1/2", "무용 12/80"]}]}]
	main.call("_show_tab", "record")
	await process_frame
	await process_frame
	var near_line := _first_label_with(main, "부족 · ")
	var near_lines := near_line.text.split("\n").size() if near_line != null else 0
	_check(near_line != null and near_line.text.replace("\n", " ") == near_source and near_lines >= 2 and near_line.get_line_count() == near_lines, "가까운 진로 부족 줄은 띄어쓰기에서만 줄바꿈 [%s]" % ("" if near_line == null else near_line.text.replace("\n", " / ")))


# 직접 고른 원정은 시험보다 먼저 한다(이슈 #12, AC-EXP-05). 화면은 겹치는 시험을 알리고, 출발 뒤 불참 알림을 띄운다.
func _check_manual_expedition(main: Node) -> void:
	var engine: Object = main.get("_engine") as Object
	var state: Dictionary = (engine.call("get_state") as Dictionary).duplicate(true)
	state["unlocks"] = {"stage": 7, "announced": 7, "tipsSeen": state.get("unlocks", {}).get("tipsSeen", [])}
	for stat_key: String in ["stamina", "combat", "magic", "dance", "art", "communication", "cooking", "intelligence", "strength", "morals", "refinement"]:
		(state["stats"] as Dictionary)[stat_key] = 600.0
	state["worldTier"] = 6
	(state["time"] as Dictionary)["slot"] = 20
	(state["meters"] as Dictionary)["energy"] = 100.0
	(state["meters"] as Dictionary)["stress"] = 0.0
	(state["bigValues"] as Dictionary)["gold"] = BigValue.from_number(1.0e9)
	state["activeTask"] = null
	state["activityQueue"] = []
	main.call("_adopt_engine_result", engine.call("initialize_from_state", state))
	var ui_state: Dictionary = main.get("_state") as Dictionary
	ui_state["lastPlannerDecision"] = {"rejected": {"ADV_VOLCANO": "예정 도전 우선: 21번 슬롯", "REST_RESORT": "예정 도전 우선: 21번 슬롯"}}
	_check(str(main.call("_activity_lock_reason", "ADV_VOLCANO")) == "", "시험과 겹친 원정은 잠금이 아님")
	# 엔진은 상태를 불러올 때 다음 활동을 미리 고르므로, 빠지는 시험은 화면이 가진 상태로 계산한 값을 기준으로 본다.
	var conflicts: Array = engine.call("activity_schedule_conflicts", "ADV_VOLCANO", ui_state) as Array
	var conflict_ids: Array = []
	for raw_conflict: Variant in conflicts:
		conflict_ids.append(str((raw_conflict as Dictionary).get("id", "")))
	var first_day := (int((conflicts[0] as Dictionary).get("slot", 1)) - 1) % 28 + 1 if not conflicts.is_empty() else 0
	var expected_warning := str(main.call("_expedition_conflict_text", conflicts, true))
	# 겹치는 시험이 둘이면 날짜와 이름을 모두, 셋 이상이면 둘 뒤에 "외 N개".
	var two := str(main.call("_expedition_conflict_text", [{"id": "CH_CONTEST_COOKING", "slot": 21}, {"id": "CH_LEAGUE_EXPEDITION", "slot": 24}], true))
	var three := str(main.call("_expedition_conflict_text", [{"id": "CH_EXAM_ACADEMY", "slot": 4}, {"id": "CH_EXAM_MAGIC", "slot": 7}, {"id": "CH_SPORT_MARTIAL", "slot": 10}], true))
	_check(two == "21일째 계절 요리 경연, 24일째 개척 원정 리그와 겹쳐요. 출발하면 그 시험에 빠져요" and three.begins_with("4일째 아카데미 종합 시험, 7일째 마법 안전 실기 외 1개와 겹쳐요"), "겹치는 시험 이름을 둘까지 날짜와 함께 [%s / %s]" % [two, three])
	var names: Array[String] = []
	for raw_id: Variant in conflict_ids:
		names.append(str(main.call("_activity_name_by_id", str(raw_id))))
	_check(not conflict_ids.is_empty(), "21일째 붉은 능선 원정은 시험과 겹침 %s" % str(conflict_ids))
	_check(str(main.call("_activity_lock_reason", "REST_RESORT")).begins_with("다음 시즌"), "원정이 아닌 활동의 시험 겹침은 그대로 잠금")
	main.call("_open_sheet", "world")
	await process_frame
	await process_frame
	var world_sheet := _find_screen_node(main, "world")
	var warning: Label = null
	var start_button: Button = null
	if world_sheet != null:
		for raw_node: Node in world_sheet.find_children("*", "", true, false):
			if raw_node is Label and (raw_node as Label).text.replace("\n", " ") == expected_warning:
				warning = raw_node as Label
			elif raw_node is Button and str(raw_node.get_meta("ui_id", "")) == "world_ADV_VOLCANO":
				start_button = raw_node as Button
	_check(warning != null and warning.get_theme_color("font_color") == PixelTokens.ACCENT, "월드 원정 카드가 겹치는 시험을 강조색으로 알림 [%s]" % expected_warning)
	_check(start_button != null and not start_button.disabled and start_button.text == "시험 빠지고 출발", "월드 원정 버튼은 시험 빠지고 출발 [%s]" % ("" if start_button == null else start_button.text))
	main.call("_close_sheet")
	await process_frame
	main.set("_activity_filter", "adventure")
	main.call("_show_tab", "activity")
	await process_frame
	await process_frame
	var row_warning := _row_label(main, "ADV_VOLCANO", "%d일째 시험에 빠져요" % first_day)
	var row_button: Button = null
	for raw_node: Node in main.find_children("*", "Button", true, false):
		if str(raw_node.get_meta("ui_id", "")) == "activity_run_ADV_VOLCANO" and (raw_node as Button).is_visible_in_tree():
			row_button = raw_node as Button
	_check(row_warning != null and _text_fits(row_warning) and row_button != null and not row_button.disabled, "활동 탭 원정 행은 시험에 빠진다고 알리고 1회를 누를 수 있음")
	# 누르는 순간 겹침이 화면에 보인 안내와 다르면(열어 둔 사이 자동 진행이 지남) 출발하지 않고 다시 보여 준다.
	main.call("_run_activity", "ADV_VOLCANO", ["CH_NOT_SHOWN"])
	await process_frame
	var stale_toast := (main.get("_toast_label") as Label).text.replace("\n", " ")
	var stale_mastery := int(((main.get("_state") as Dictionary).get("mastery", {}) as Dictionary).get("ADV_VOLCANO", 0))
	_check(stale_mastery == 0 and stale_toast.contains("일정이 바뀌었어요"), "안내와 다른 겹침이면 출발하지 않고 다시 확인 [%s]" % stale_toast)
	# 자동 진행으로는 고를 날이 없는 원정은 자동 큐에 넣을 수 없다(넣으면 끝내 실행되지 않는다). 짧은 원정은 넣을 수 있다.
	main.call("_open_activity_detail", "ADV_VOLCANO")
	await process_frame
	await process_frame
	var queue_button := _button_with_id(main, "detail_queue")
	var volcano_queue_blocked := queue_button != null and queue_button.disabled
	var volcano_reason := _first_label_with(main, "자동 진행은 시험을 지켜서") != null
	# 상세 시트에서도 안내와 다른 겹침이면 출발하지 않고 같은 시트를 다시 보여 준다.
	main.call("_run_activity_from_detail", "ADV_VOLCANO", ["CH_NOT_SHOWN"])
	await process_frame
	_check(_find_screen_node(main, "activity_detail") != null and int(((main.get("_state") as Dictionary).get("mastery", {}) as Dictionary).get("ADV_VOLCANO", 0)) == 0, "상세 시트에서 안내와 다른 겹침이면 시트를 다시 보여 줌")
	main.call("_close_sheet")
	await process_frame
	main.call("_open_activity_detail", "ADV_FOREST")
	await process_frame
	await process_frame
	var forest_queue := _button_with_id(main, "detail_queue")
	var forest_queue_open := forest_queue != null and not forest_queue.disabled
	_check(volcano_queue_blocked and volcano_reason and forest_queue_open, "고를 날이 없는 원정만 자동 큐 막음, 이유 표시")
	main.call("_close_sheet")
	await process_frame
	main.call("_run_activity", "ADV_VOLCANO", conflict_ids)
	await process_frame
	var toast := (main.get("_toast_label") as Label).text.replace("\n", " ")
	var mastery: Dictionary = (main.get("_state") as Dictionary).get("mastery", {}) as Dictionary
	_check(int(mastery.get("ADV_VOLCANO", 0)) > 0 and toast.contains("%s에는 불참했어요" % ", ".join(names)), "원정 출발 뒤 불참한 시험을 알림 [%s]" % toast.replace("\n", " / "))
	# 자동 진행이 고른 같은 원정이 진행 중이면 이어 하는 것이라 거짓 겹침 안내가 없다(남은 칸만 본다).
	var running_state: Dictionary = main.get("_state") as Dictionary
	var saved_task: Variant = running_state.get("activeTask")
	var saved_slot := int((running_state["time"] as Dictionary).get("slot", 0))
	(running_state["time"] as Dictionary)["slot"] = 21
	running_state["activeTask"] = {"id": "ADV_VOLCANO", "activityId": "ADV_VOLCANO", "remainingSlots": 1, "durationSlots": 4, "worldTier": 6, "paidCost": BigValue.zero()}
	_check((main.call("_expedition_conflicts", "ADV_VOLCANO") as Array).is_empty(), "진행 중인 같은 원정에는 겹침 안내 없음")
	running_state["activeTask"] = saved_task
	(running_state["time"] as Dictionary)["slot"] = saved_slot
	# 시즌 경계를 넘는 원정이 다음 시즌 시험과 겹치면 "다음 시즌"으로 구분해 알린다.
	var boundary: Dictionary = (engine.call("get_state") as Dictionary).duplicate(true)
	(boundary["time"] as Dictionary)["slot"] = 26
	boundary["activeTask"] = null
	boundary["activityQueue"] = []
	(boundary["meters"] as Dictionary)["energy"] = 100.0
	(boundary["meters"] as Dictionary)["stress"] = 0.0
	main.call("_adopt_engine_result", engine.call("initialize_from_state", boundary))
	var boundary_state: Dictionary = main.get("_state") as Dictionary
	var rift_conflicts: Array = engine.call("activity_schedule_conflicts", "ADV_RIFT", boundary_state) as Array
	var next_season := false
	if not rift_conflicts.is_empty():
		next_season = (int((rift_conflicts[0] as Dictionary).get("slot", 0)) - 1) / 28 > int((boundary_state["time"] as Dictionary).get("slot", 0)) / 28
	main.set("_activity_filter", "adventure")
	main.call("_show_tab", "activity")
	await process_frame
	await process_frame
	var rift_row := _row_label(main, "ADV_RIFT", "다음 시즌")
	_check(next_season and rift_row != null and _text_fits(rift_row) and str(main.call("_expedition_conflict_text", rift_conflicts, true)).begins_with("다음 시즌 "), "다음 시즌 시험과 겹치는 원정은 다음 시즌으로 구분 [%s]" % ("" if rift_row == null else rift_row.text))
	# 알림 띠도 띄어쓰기에서만 줄을 바꾼다("불참했 / 어요" 방지).
	var toast_label := main.get("_toast_label") as Label
	var toast_lines := toast_label.text.split("\n").size()
	_check(toast_lines >= 2 and toast_label.get_line_count() == toast_lines, "알림 띠는 띄어쓰기에서만 줄바꿈 [%s]" % toast_label.text.replace("\n", " / "))
	main.set("_activity_filter", "education")


func _button_with_id(main: Node, ui_id: String) -> Button:
	for raw_node: Node in main.find_children("*", "Button", true, false):
		if str(raw_node.get_meta("ui_id", "")) == ui_id and (raw_node as Button).is_visible_in_tree() and not raw_node.is_queued_for_deletion():
			return raw_node as Button
	return null


func _first_label_with(main: Node, prefix: String) -> Label:
	for raw_label: Node in main.find_children("*", "Label", true, false):
		if (raw_label as Label).is_visible_in_tree() and (raw_label as Label).text.begins_with(prefix):
			return raw_label as Label
	return null


# 활동 행(meta activity_id) 안에서 prefix로 시작하는 글자를 찾는다.
func _row_label(main: Node, activity_id: String, prefix: String) -> Label:
	for raw_node: Node in main.find_children("*", "PanelContainer", true, false):
		if not (raw_node as Control).is_visible_in_tree() or str(raw_node.get_meta("activity_id", "")) != activity_id:
			continue
		for raw_label: Node in raw_node.find_children("*", "Label", true, false):
			if (raw_label as Label).text.begins_with(prefix):
				return raw_label as Label
	return null


func _text_fits(label: Label) -> bool:
	var font: Font = label.get_theme_font("font")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	return width <= label.size.x + 0.5


func _descendant_group_nodes(ancestor: Node, group_name: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for candidate: Node in get_nodes_in_group(group_name):
		if candidate == ancestor or ancestor.is_ancestor_of(candidate):
			result.append(candidate)
	return result


func _find_screen_node(ancestor: Node, screen_id: String) -> Node:
	if str(ancestor.get_meta("screen_id", "")) == screen_id:
		return ancestor
	for child: Node in ancestor.get_children():
		var found: Node = _find_screen_node(child, screen_id)
		if found != null:
			return found
	return null


func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("[PASS] %s" % label)
	else:
		_failures.append(label)
		push_error("[FAIL] %s" % label)


func _finish() -> void:
	_cleanup_test_save()
	if _failures.is_empty():
		print("[SMOKE] PASS checks=%d" % _passes)
		quit(0)
		return
	print("[SMOKE] FAIL passed=%d failed=%d" % [_passes, _failures.size()])
	for failure: String in _failures:
		print("[SMOKE]   - %s" % failure)
	quit(1)


func _prepare_test_save() -> void:
	_cleanup_test_save()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE_PATH)


func _cleanup_test_save() -> void:
	var absolute := ProjectSettings.globalize_path(SAVE_PATH)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
