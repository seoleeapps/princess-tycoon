extends Control

const PixelTheme = preload("res://src/ui/pixel/pixel_theme.gd")
const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const PixelText = preload("res://src/ui/pixel/pixel_text.gd")
const PixelTraineeView = preload("res://src/ui/pixel/pixel_trainee_view.gd")
const ResultFeedbackLayer = preload("res://src/ui/result_feedback_layer.gd")
const ActivityProgressRing = preload("res://src/ui/activity_progress_ring.gd")
const LocalAnalyticsPort = preload("res://src/ports/local_analytics_port.gd")
const NoOpAdPort = preload("res://src/ports/noop_ad_port.gd")
const NoOpIapPort = preload("res://src/ports/noop_iap_port.gd")
const SynthAudioPort = preload("res://src/ports/synth_audio_port.gd")
const ICON_DIR := "res://assets/pixel/icons/"

const TABS := [
	{"id": "home", "label": "홈"},
	{"id": "plan", "label": "계획"},
	{"id": "activity", "label": "활동"},
	{"id": "growth", "label": "성장"},
	{"id": "record", "label": "기록"},
]

const PRESETS := [
	{"id": "balanced", "name": "균형", "hint": "고른 성장"},
	{"id": "martial", "name": "무예", "hint": "전투·체력"},
	{"id": "scholar", "name": "학문", "hint": "지력·마법"},
	{"id": "artist", "name": "예술", "hint": "예술·무용"},
	{"id": "leader", "name": "리더십", "hint": "기품·소통"},
	{"id": "care", "name": "돌봄", "hint": "간호·도덕"},
	{"id": "explorer", "name": "탐험", "hint": "모험·전투"},
	{"id": "prosperity", "name": "번영", "hint": "골드·교류"},
	{"id": "custom", "name": "직접 설계", "hint": "세부 가중치"},
]

const STAT_LABELS := {
	"stamina": "체력", "strength": "근력", "intelligence": "지력",
	"refinement": "기품", "sensitivity": "감수성", "style": "스타일",
	"discipline": "절제", "morals": "도덕", "faith": "신앙",
	"combat": "전투", "magic": "마법", "etiquette": "예절",
	"communication": "소통", "art": "예술", "cooking": "요리",
	"housework": "생활", "nursing": "간호", "dance": "무용",
}

const RELATION_LABELS := {
	"guardian": "후견인", "steward": "비서", "rival": "라이벌", "citizens": "왕국 시민",
}

const FALLBACK_ACTIVITIES := [
	{"id": "EDU_LITERATURE", "kind": "education", "name": "왕립 교양학", "description": "읽고 토론하며 사고와 소통을 기른다.", "baseCost": 150, "energyDelta": -8, "stressDelta": 6, "primaryStat": "intelligence"},
	{"id": "EDU_FENCING", "kind": "education", "name": "왕립 검술", "description": "정교한 검술과 절제를 익힌다.", "baseCost": 220, "energyDelta": -14, "stressDelta": 8, "primaryStat": "combat"},
	{"id": "EDU_PAINTING", "kind": "education", "name": "빛의 회화", "description": "관찰과 표현을 작품으로 남긴다.", "baseCost": 180, "energyDelta": -8, "stressDelta": 4, "primaryStat": "art"},
	{"id": "JOB_FARM", "kind": "job", "name": "학당 농장", "description": "계절 작물을 돌보며 보수를 얻는다.", "baseReward": 210, "energyDelta": -15, "stressDelta": 5, "primaryStat": "stamina"},
	{"id": "JOB_THEATER", "kind": "job", "name": "극장 운영", "description": "공연을 지원하며 소통과 감각을 익힌다.", "baseReward": 280, "energyDelta": -12, "stressDelta": 8, "primaryStat": "communication"},
	{"id": "REST_HOME", "kind": "rest", "name": "기숙사 휴식", "description": "안전하게 쉬며 에너지를 회복한다.", "baseCost": 0, "energyDelta": 38, "stressDelta": -24, "primaryStat": "stamina"},
	{"id": "REST_WALK", "kind": "rest", "name": "왕도 산책", "description": "도시를 걸으며 생각을 정돈한다.", "baseCost": 0, "energyDelta": 18, "stressDelta": -16, "primaryStat": "sensitivity"},
	{"id": "ADV_FOREST", "kind": "adventure", "name": "별빛 숲 원정", "description": "세 노드를 자동 탐사하고 전리품을 얻는다.", "baseCost": 60, "energyDelta": -20, "stressDelta": 9, "primaryStat": "combat"},
	{"id": "CH_EXAM_ACADEMY", "kind": "challenge", "name": "아카데미 종합시험", "description": "성장 방향과 기초 역량을 종합 평가한다.", "baseCost": 100, "energyDelta": -10, "stressDelta": 10, "primaryStat": "intelligence"},
	{"id": "CH_SPORT_DANCE", "kind": "challenge", "name": "왕도 무용 리그", "description": "무용과 표현력으로 라이벌과 겨룬다.", "baseCost": 120, "energyDelta": -14, "stressDelta": 8, "primaryStat": "dance"},
]

var _engine: Object = null
var _state: Dictionary = {}
var _seed := 1729
var _current_tab := "home"
var _activity_filter := "education"
# 플래너 이유 이름 중 개발 용어처럼 들리는 것을 쉬운 말로 바꿔 보여 준다.
const REASON_DISPLAY := {"프리셋 선호": "방향 선호"}
# 첫 진입 안내가 붙는 화면. 한 화면 방문에는 안내를 하나만 보여 준다.
const TIP_SCREEN := {
	"plan": "plan", "customWeights": "plan", "rules": "plan", "bannedTags": "plan",
	"growth": "growth", "relations": "growth", "challenge": "activity",
	"record": "record", "contracts": "record", "world": "world", "league": "world",
	"shop": "shop", "events": "event",
}
# 이번 화면 방문에서 보여 주는 첫 진입 안내(다른 탭으로 가면 비운다).
var _tips_showing: Dictionary = {}
const EXPEDITION_SCHEDULE_CHANGED := "일정이 바뀌었어요. 겹치는 시험을 다시 확인해 주세요."
var _unlock_notice_text := ""
var _unlock_notice_until := 0
# 시험 겹침이 풀리는 slot은 행마다 잠금 판단과 문구에 함께 쓰므로 같은 프레임·같은 상태에서는 한 번만 계산한다.
var _free_slot_memo := {}
var _free_slot_memo_frame := -1
var _unlock_teaser_tab: Button
var _nav_row: HBoxContainer
var _gift_target := "citizens"
var _activity_elapsed := 0.0
var _auto_running := true
var _nav_buttons: Dictionary = {}
var _activities: Array = []
var _items: Array = []
var _events: Array = []
var _runtime_config: Dictionary = {}
var _analytics_port: RefCounted
var _ad_port: RefCounted
var _iap_port: RefCounted
var _audio_port: Node

var _content_host: Control
var _modal_layer: Control
var _header_time_label: Label
var _header_gold_label: Label
var _activity_label: Label
var _reason_label: Label
var _activity_progress: Control
var _pause_button: Button
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_serial := 0
var _result_feedback_layer: Control
var _trainee_name_edit: LineEdit
var _home_avatar: Control
var _detail_activity_id := ""
var _rendered_tab := ""
var _page_dirty := false
var _scroll_probe_value := -1
var _scroll_still_frames := 0
var _status_panel: PanelContainer
var _status_slot: MarginContainer
var _header_name_label: Label
var _header_tier_label: Label


func _ready() -> void:
	theme = PixelTheme.build(false)
	# 도트는 어느 뷰포트에서 그려도 nearest로 키운다(SubViewport는 프로젝트 기본 필터를 물려받지 않는다).
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_runtime_config = _load_json_dictionary("res://data/config.json")
	_state = _fallback_state()
	_activities = _load_activities()
	_items = _load_json_array("res://data/items.json")
	_events = _load_json_array("res://data/events.json")
	_initialize_engine()
	theme = PixelTheme.build(bool(_read(["settings", "highContrast"], false)))
	_auto_running = bool(_read(["settings", "autoRun"], true))
	_initialize_runtime_ports()
	_build_shell()
	_show_tab("home")
	_refresh_chrome()
	set_process(true)
	if int(_state.get("pendingOfflineSlots", 0)) > 0:
		call_deferred("_open_sheet", "offline")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_track_event(&"app_background", {"slot": int(_read(["time", "slot"], 0))})
		_persist_silently()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_sync_engine_state()
		var resume_now := _now_unix()
		var last_boundary := int(_state.get("lastSimulatedAt", 0))
		# Paused growth still needs a zero-slot settlement for event expiry, and
		# clock rollback must preserve a future boundary before online ticks resume.
		var needs_boundary_settlement := not bool(_read(["settings", "autoRun"], true)) or last_boundary > resume_now
		if needs_boundary_settlement and _engine != null and _engine.has_method("settle_offline"):
			var boundary_result = _engine.call("settle_offline", resume_now)
			_adopt_engine_result(boundary_result)
			_absorb_offline_unlocks(boundary_result)
			_persist_silently()
		_auto_running = bool(_read(["settings", "autoRun"], true))
		_state["pendingOfflineSlots"] = _pending_offline_slots()
		_refresh_chrome()
		if int(_state.get("pendingOfflineSlots", 0)) > 0:
			call_deferred("_open_sheet", "offline")


func _process(delta: float) -> void:
	_track_scroll_motion()
	if _page_dirty and not _list_in_motion():
		_page_dirty = false
		_render_current_page()
	if not _auto_running or int(_state.get("pendingOfflineSlots", 0)) > 0:
		return
	var seconds_per_slot := _config_float("onlineSecondsPerSlot", 5.0)
	seconds_per_slot = maxf(0.01, seconds_per_slot)
	_activity_elapsed += delta
	if _activity_progress != null:
		_activity_progress.value = clampf(_activity_elapsed / seconds_per_slot * 100.0, 0.0, 100.0)
	if _home_avatar != null and is_instance_valid(_home_avatar):
		_home_avatar.call("set_progress", _activity_elapsed / seconds_per_slot)
	if _activity_elapsed >= seconds_per_slot:
		_activity_elapsed = fmod(_activity_elapsed, seconds_per_slot)
		_advance_slots(1, false)


func _initialize_engine() -> void:
	var script_path := ""
	for global_class in ProjectSettings.get_global_class_list():
		if str(global_class.get("class", "")) == "GameEngine":
			script_path = str(global_class.get("path", ""))
			break
	if script_path.is_empty() and ResourceLoader.exists("res://src/core/game_engine.gd"):
		script_path = "res://src/core/game_engine.gd"
	if script_path.is_empty() or not ResourceLoader.exists(script_path):
		return
	var engine_script = load(script_path)
	if engine_script == null or not engine_script.can_instantiate():
		return
	_engine = engine_script.new()
	var test_save_path := str(ProjectSettings.get_setting("princess_tycoon/testing/save_path", ""))
	if not test_save_path.is_empty() and _engine.has_method("set_save_path"):
		_engine.call("set_save_path", test_save_path)
	var initialized = null
	var loaded_ok := false
	if _engine.has_method("load_save"):
		var loaded = _engine.call("load_save")
		loaded_ok = loaded is Dictionary and bool((loaded as Dictionary).get("ok", false))
	if not loaded_ok and _engine.has_method("initialize"):
		initialized = _engine.call("initialize", _seed)
	if _engine.has_method("get_state"):
		_sync_engine_state()
	elif typeof(initialized) == TYPE_DICTIONARY:
		_state = _deep_merge(_engine_state_shape(), initialized)
	var last_seen := int(_state.get("lastSimulatedAt", 0))
	var now := _now_unix()
	if last_seen <= 0 and _engine.has_method("advance_slots"):
		_stamp_engine_time_boundary(now)
		_persist_silently()
	elif loaded_ok and (last_seen > now or not bool(_read(["settings", "autoRun"], true))) and _engine.has_method("settle_offline"):
		var startup_result = _engine.call("settle_offline", now)
		_adopt_engine_result(startup_result)
		_absorb_offline_unlocks(startup_result)
		_persist_silently()
	_state["pendingOfflineSlots"] = _pending_offline_slots()


func _sync_engine_state() -> void:
	if _engine == null or not _engine.has_method("get_state"):
		return
	var snapshot = _engine.call("get_state")
	if typeof(snapshot) == TYPE_DICTIONARY:
		_state = _deep_merge(_engine_state_shape(), snapshot)
	elif typeof(snapshot) == TYPE_OBJECT and snapshot != null and snapshot.has_method("to_dict"):
		var converted = snapshot.call("to_dict")
		if typeof(converted) == TYPE_DICTIONARY:
			_state = _deep_merge(_engine_state_shape(), converted)


# 엔진 상태를 받을 때의 기본 틀. 엔진이 없을 때 쓰는 데모 값(숙련·칭호·최근 결과 등)이
# 실제 수련생 상태에 섞이지 않도록 진행 기록 항목은 비워 둔다.
func _engine_state_shape() -> Dictionary:
	var shape := _fallback_state()
	for key in ["mastery", "careerTitles", "lastResult", "activeTask", "generatedContent"]:
		shape[key] = {}
	for key in ["recentActivities", "eventInbox", "inventory"]:
		shape[key] = []
	return shape


func _fallback_state() -> Dictionary:
	return {
		"schemaVersion": 2,
		"seed": _seed,
		"traineeName": "아리아",
		"time": {"slot": 6, "season": 1, "year": 1},
		"stats": {
			"stamina": 86.0, "strength": 48.0, "intelligence": 112.0,
			"refinement": 74.0, "sensitivity": 67.0, "style": 58.0,
			"discipline": 91.0, "morals": 65.0, "faith": 42.0,
			"combat": 51.0, "magic": 88.0, "etiquette": 70.0,
			"communication": 96.0, "art": 62.0, "cooking": 44.0,
			"housework": 38.0, "nursing": 55.0, "dance": 61.0,
		},
		"meters": {"energy": 82.0, "stress": 24.0, "reputation": 50.0, "integrityViolations": 0},
		"bigValues": {
			"gold": {"mantissa": 3.0, "exponent": 3},
			"renown": {"mantissa": 8.4, "exponent": 1},
			"lifetimeRenown": {"mantissa": 8.4, "exponent": 1},
		},
		"growthPolicy": {
			"preset": "scholar", "weights": {}, "bannedTags": [],
			"reserveGold": {"mantissa": 3.0, "exponent": 2},
			"maxStress": 72.0, "riskTolerance": 0.35,
		},
		"activeTask": {
			"id": "EDU_LITERATURE", "activityId": "EDU_LITERATURE",
			"name": "왕립 교양학", "reason": "학문 방향과 계약 목표에 가장 잘 맞아요.",
		},
		"recentActivities": ["REST_WALK", "JOB_THEATER", "EDU_LITERATURE"],
		"lastResult": {"title": "토론 발표 완료", "summary": "지력 +8.4 · 소통 +4.1 · 숙련 +1"},
		"mastery": {"EDU_LITERATURE": 14, "EDU_MAGIC": 8, "JOB_THEATER": 6},
		"inventory": [{"id": "ITEM_TEA", "count": 3}],
		"equipment": {"outfit": "OUTFIT_PLAIN", "weapon": null, "armor": null, "accessory": "ACC_RIBBON"},
		"relations": {"guardian": 100, "steward": 100, "rival": 18, "citizens": 62},
		"worldTier": 1,
		"seasonHistory": [],
		"generatedContent": {
			"contracts": [
				{"name": "도서관의 새 기준", "progress": 3, "target": 8, "reward": "명성 35"},
				{"name": "균형 잡힌 일주일", "progress": 2, "target": 5, "reward": "골드 480"},
				{"name": "별빛 숲 기록", "progress": 0, "target": 3, "reward": "장비 상자"},
			],
			"rivals": [
				{"name": "붉은 매의 세린", "strength": "무예", "score": 184},
				{"name": "새벽 기록관 루나", "strength": "학문", "score": 177},
			],
		},
		"eventInbox": [{"id": "EV_GUARDIAN_LETTER", "name": "후견인의 편지", "description": "최근 성장 방향을 응원하는 편지가 도착했어요.", "choices": [{"id": "reply", "text": "답장을 쓴다"}, {"id": "keep", "text": "소중히 보관한다"}]}],
		"careerTitles": {"END_SCHOLAR": {"name": "왕립 연구자", "stars": 1}},
		"settings": {"autoRun": true, "reducedMotion": false, "sound": true, "highContrast": false},
	}


func _build_shell() -> void:
	name = "PrincessTycoonMobileUI"
	set_meta("screen_id", "home")
	set_meta("available_screen_ids", PackedStringArray(["home", "plan", "activity", "growth", "record", "world", "shop", "settings", "offline", "event", "profile", "continue"]))
	var background := ColorRect.new()
	background.color = PixelTokens.STRIP_DARK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	column.add_child(_build_header())
	# 현재 활동 창은 하나만 만든다. 홈에서는 장면 위로, 다른 탭에서는 이 자리로 옮겨 항상 보이게 한다.
	_status_slot = MarginContainer.new()
	_status_slot.name = "StatusSlot"
	for side in ["left", "right", "top"]:
		_status_slot.add_theme_constant_override("margin_" + side, PixelTokens.EDGE)
	column.add_child(_status_slot)
	_status_panel = _build_activity_status()
	_status_slot.add_child(_status_panel)

	_content_host = Control.new()
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_content_host)
	column.add_child(_build_navigation())

	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_layer.z_index = 50
	add_child(_modal_layer)
	_result_feedback_layer = ResultFeedbackLayer.new()
	_result_feedback_layer.name = "ResultFeedbackLayer"
	_modal_layer.add_child(_result_feedback_layer)
	_build_toast()


func _build_header() -> Control:
	var strip := PanelContainer.new()
	strip.name = "Header"
	strip.theme_type_variation = PixelTheme.panel_variation("strip")
	strip.custom_minimum_size.y = 56.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP)
	strip.add_child(row)

	var menu := _button("", _open_sheet.bind("menu"), "secondary", 44.0, "menu")
	menu.icon = _icon_texture("menu")
	menu.tooltip_text = "메뉴"
	menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.custom_minimum_size.x = 44.0
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(menu)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	_header_name_label = _label(str(_state.get("traineeName", "수련생")), 16, PixelTokens.ON_STRIP)
	_header_time_label = _label("", 16, PixelTokens.ON_STRIP_MUTED)
	for label in [_header_name_label, _header_time_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title_box.add_child(label)
	row.add_child(title_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_theme_constant_override("separation", 2)
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_END
	gold_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	gold_row.add_child(_icon("coin"))
	_header_gold_label = _label("", 16, PixelTokens.ON_STRIP, HORIZONTAL_ALIGNMENT_RIGHT)
	_header_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_header_gold_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	gold_row.add_child(_header_gold_label)
	right.add_child(gold_row)
	_header_tier_label = _label("", 16, PixelTokens.ON_STRIP_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	_header_tier_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	right.add_child(_header_tier_label)
	row.add_child(right)
	return strip


func _build_activity_status() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ActivityStatus"
	panel.theme_type_variation = PixelTheme.panel_variation("window")
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP)
	panel.add_child(row)

	_activity_progress = ActivityProgressRing.new()
	_activity_progress.tooltip_text = "현재 활동 진행률"
	row.add_child(_activity_progress)
	# 글이 좁은 폭에서 말줄임되므로, 누르면 현재 활동과 다음 선택 이유 전체를 알림으로 보여 준다.
	var text_button := _button("", _show_status_detail, "secondary", 44.0, "status_detail")
	text_button.theme_type_variation = "PixelRowButton"
	text_button.tooltip_text = "현재 활동과 선택 이유 보기"
	text_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text_box := VBoxContainer.new()
	text_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 4)
	_activity_label = _label("현재 활동", 16, PixelTokens.INK)
	_reason_label = _label("", 16, PixelTokens.INK_MUTED)
	for label in [_activity_label, _reason_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text_box.add_child(label)
	text_button.add_child(text_box)
	row.add_child(text_button)

	var offline := _button("방치 8시간", _open_sheet.bind("offline"), "secondary", 44.0, "offline_open")
	offline.text = "방치 %s" % _duration_label(_config_int("offlineCapSeconds", 28800))
	offline.theme_type_variation = "PixelButtonCompactSecondary"
	offline.custom_minimum_size.x = 92.0
	offline.tooltip_text = "방치 최대 %s · 오프라인 정산" % _duration_label(_config_int("offlineCapSeconds", 28800))
	offline.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(offline)
	_pause_button = _button("", _toggle_auto, "gold", 44.0, "pause")
	_pause_button.custom_minimum_size.x = 44.0
	_pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(_pause_button)
	return panel


func _build_navigation() -> Control:
	var strip := PanelContainer.new()
	strip.name = "Navigation"
	strip.theme_type_variation = PixelTheme.panel_variation("strip")
	strip.custom_minimum_size.y = 86.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	strip.add_child(row)
	_nav_row = row
	row.resized.connect(_layout_navigation)
	for definition in TABS:
		var tab_id := str(definition["id"])
		var tab_button := _button(str(definition["label"]), _show_tab.bind(tab_id), "secondary", 74.0, "tab_%s" % tab_id)
		tab_button.theme_type_variation = "PixelTab"
		tab_button.icon = _icon_texture(tab_id)
		tab_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.toggle_mode = true
		row.add_child(tab_button)
		tab_button.add_to_group("critical_cta")
		_nav_buttons[tab_id] = tab_button
	# 다음 단계가 탭을 열면 그 탭 하나만 자물쇠와 조건으로 예고한다(GDD §2.2).
	_unlock_teaser_tab = _button("", _show_unlock_teaser, "secondary", 74.0, "tab_teaser")
	_unlock_teaser_tab.theme_type_variation = "PixelTab"
	_unlock_teaser_tab.icon = _icon_texture("lock")
	_unlock_teaser_tab.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_teaser_tab.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_unlock_teaser_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unlock_teaser_tab.visible = false
	row.add_child(_unlock_teaser_tab)
	return strip


func _show_tab(tab_id: String) -> void:
	if not _feature_open(tab_id):
		tab_id = "home"
	if tab_id != _current_tab:
		for screen in ["plan", "growth", "activity", "record", "home"]:
			_tips_showing.erase(screen)
	_current_tab = tab_id
	for key in _nav_buttons:
		var tab_button: Button = _nav_buttons[key]
		tab_button.button_pressed = key == tab_id
		tab_button.theme_type_variation = "PixelTabSelected" if key == tab_id else "PixelTab"
	_render_current_page()
	_track_event(&"screen_view", {"screen": tab_id})


func _render_current_page() -> void:
	if _content_host == null:
		return
	_home_avatar = null
	# 자동 진행이 같은 탭을 다시 그릴 때 스크롤 위치를 지킨다(탭을 바꾸면 맨 위에서 시작).
	var previous_scroll := 0
	if _rendered_tab == _current_tab:
		for child in _content_host.get_children():
			if child is ScrollContainer and not child.is_queued_for_deletion():
				previous_scroll = (child as ScrollContainer).scroll_vertical
	# 페이지를 지우기 전에 공용 현재 활동 창을 셸 자리로 되돌린다.
	if _status_panel != null and _status_slot != null and _status_panel.get_parent() != _status_slot:
		_status_panel.reparent(_status_slot, false)
	if _status_slot != null:
		_status_slot.visible = _current_tab != "home"
	var old_pages: Array = _content_host.get_children()
	var page: Control
	match _current_tab:
		"plan": page = _build_plan_page()
		"activity": page = _build_activity_page()
		"growth": page = _build_growth_page()
		"record": page = _build_record_page()
		_: page = _build_home_page()
	page.name = "Screen_%s" % _current_tab.capitalize()
	page.set_meta("screen_id", _current_tab)
	set_meta("screen_id", _current_tab)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(page)
	_rendered_tab = _current_tab
	if previous_scroll > 0 and page is ScrollContainer:
		page.modulate.a = 0.0
		_swap_in_after_layout(page, page as ScrollContainer, previous_scroll, old_pages)
	else:
		for old in old_pages:
			(old as Node).queue_free()


func _page_scroll() -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, PixelTokens.EDGE)
	margin.add_theme_constant_override("margin_bottom", PixelTokens.GAP)
	scroll.add_child(margin)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", PixelTokens.GAP)
	margin.add_child(body)
	return {"scroll": scroll, "body": body}


func _build_home_page() -> Control:
	var page := _page_scroll()
	var body: VBoxContainer = page["body"]

	# 방 장면: 수련생, 활동 말풍선, 장면 위 현재 활동 창
	var stage := Control.new()
	stage.name = "HomeScene"
	stage.custom_minimum_size.y = 440.0
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	stage.clip_contents = true
	var avatar := PixelTraineeView.new()
	_home_avatar = avatar
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.set_profile(_policy_preset())
	avatar.set_environment(_profile_environment())
	avatar.set_equipment(_equipment_visual_state())
	avatar.set_reduced_motion(bool(_read(["settings", "reducedMotion"], false)))
	avatar.set_activity(_activity_icon_name(), _activity_elapsed / maxf(0.01, _config_float("onlineSecondsPerSlot", 5.0)))
	stage.add_child(avatar)
	var overlay := MarginContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	for side in ["left", "right", "top"]:
		overlay.add_theme_constant_override("margin_" + side, PixelTokens.GAP_SMALL)
	stage.add_child(overlay)
	if _status_panel == null:
		_status_panel = _build_activity_status()
		overlay.add_child(_status_panel)
		_refresh_chrome()
	else:
		_status_panel.reparent(overlay, false)
	var profile_chip := PanelContainer.new()
	profile_chip.theme_type_variation = PixelTheme.panel_variation("chip")
	profile_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	profile_chip.position = Vector2(8, 392)
	var profile_label := _label("%s 성장" % _preset_name(_policy_preset()), 16, PixelTokens.INK)
	profile_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	profile_chip.add_child(profile_label)
	stage.add_child(profile_chip)
	body.add_child(stage)

	# 미터 3종
	var meters := _card("window")
	var meter_row := HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", PixelTokens.GAP)
	meter_row.add_child(_meter_cell("energy", "에너지", float(_read(["meters", "energy"], 0)), 100.0))
	meter_row.add_child(_meter_cell("stress", "스트레스", float(_read(["meters", "stress"], 0)), maxf(1.0, float(_read(["growthPolicy", "maxStress"], 100.0)))))
	meter_row.add_child(_meter_cell("reputation", "평판", float(_read(["meters", "reputation"], 0)), 100.0))
	meters.add_child(meter_row)
	body.add_child(meters)

	# 행동
	var quick_grid := GridContainer.new()
	quick_grid.columns = 2
	quick_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	quick_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
	var run_once := _button("자동 1회 실행", _complete_current_activity, "primary", 52.0, "run_auto_once")
	run_once.icon = _icon_texture("play")
	quick_grid.add_child(run_once)
	if _feature_open("world"):
		var world := _button("월드 출정", _open_sheet.bind("world"), "gold", 52.0, "open_world")
		world.icon = _icon_texture("world")
		quick_grid.add_child(world)
	elif _unlock_teaser_place() == "home":
		quick_grid.add_child(_unlock_teaser_button(52.0, "월드 출정"))
	if _feature_open("plan"):
		quick_grid.add_child(_button("성장 방향", _show_tab.bind("plan"), "secondary", 48.0, "open_plan"))
	if _feature_open("events"):
		var event_count := _event_inbox().size()
		var events := _button("이벤트 %d" % event_count if event_count > 0 else "이벤트 확인", _open_sheet.bind("event"), "secondary", 48.0, "open_event")
		events.icon = _icon_texture("event")
		quick_grid.add_child(events)
	_fit_grid_columns(quick_grid)
	body.add_child(quick_grid)
	# 최근 결과
	var result = _read(["lastResult"], {})
	var recent := _card("transparent")
	var recent_box := VBoxContainer.new()
	recent_box.add_theme_constant_override("separation", 4)
	var title_text := str(result.get("title", "")) if result is Dictionary else ""
	recent_box.add_child(_label("최근 · %s" % (title_text if not title_text.is_empty() else "아직 완료한 활동이 없어요"), 16, PixelTokens.INK))
	if result is Dictionary and not str(result.get("summary", "")).is_empty():
		recent_box.add_child(_label(str(result.get("summary", "")), 16, PixelTokens.INK_MUTED))
		for specialized_line: String in _result_specialized_summary_lines(result as Dictionary):
			recent_box.add_child(_label(specialized_line, 16, PixelTokens.INK_MUTED))
	recent.add_child(recent_box)
	body.add_child(recent)

	return page["scroll"]


func _build_plan_page() -> Control:
	var page := _page_scroll()
	var body: VBoxContainer = page["body"]
	body.add_child(_section_heading("성장 방향", "다음 자동 선택부터 반영돼요."))
	_add_tip(body, "plan")

	var preset_grid := GridContainer.new()
	preset_grid.columns = 2
	preset_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	preset_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
	for preset in PRESETS:
		var preset_id := str(preset["id"])
		if preset_id == "custom" and not _feature_open("customWeights"):
			continue
		var selected := preset_id == _policy_preset()
		var preset_button := _button("%s\n%s" % [preset["name"], "선택됨" if selected else preset["hint"]], _apply_preset.bind(preset_id), "gold" if selected else "secondary", 60.0, "preset_%s" % preset_id)
		preset_button.icon = _icon_texture(_preset_icon(preset_id))
		preset_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		preset_grid.add_child(preset_button)
	body.add_child(preset_grid)
	_add_tip(body, "customWeights")

	if _policy_preset() == "custom" and _feature_open("customWeights"):
		body.add_child(_section_heading("직접 설계 가중치", "합계는 늘 100%로 맞춰져요."))
		var custom_weights: Dictionary = _read(["growthPolicy", "weights"], {})
		var weight_card := _card("window")
		var weight_box := VBoxContainer.new()
		weight_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		for stat_id in STAT_LABELS:
			weight_box.add_child(_policy_slider(str(STAT_LABELS[stat_id]), "", "weight:%s" % stat_id,
				float(custom_weights.get(stat_id, 0.0)) * 100.0, 0.0, 100.0, 5.0, func(value): return "%d%%" % int(round(value))))
		for extra in [{"id": "reputation", "name": "평판"}, {"id": "gold", "name": "골드"}]:
			var extra_id := str(extra["id"])
			weight_box.add_child(_policy_slider(str(extra["name"]), "", "weight:%s" % extra_id,
				float(custom_weights.get(extra_id, 0.0)) * 100.0, 0.0, 100.0, 5.0, func(value): return "%d%%" % int(round(value))))
		weight_card.add_child(weight_box)
		body.add_child(weight_card)

	if not _feature_open("rules"):
		if _unlock_teaser_place() == "plan":
			var teaser_card := _card("transparent")
			teaser_card.add_child(_unlock_teaser_row())
			body.add_child(teaser_card)
		var early_note := _card("transparent")
		early_note.add_child(_label("바꾼 방향은 진행 중인 활동을 멈추지 않고 다음 선택부터 적용돼요.", 16, PixelTokens.INK_MUTED))
		body.add_child(early_note)
		return page["scroll"]
	body.add_child(_section_heading("안전 규칙", "활동 점수보다 먼저 지켜요."))
	_add_tip(body, "rules")
	var policy: Dictionary = _read(["growthPolicy"], {})
	var rules := _card("window")
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", PixelTokens.GAP)
	rules_box.add_child(_policy_slider("위험 허용도", "낮을수록 안전한 활동을 우선", "riskTolerance", float(policy.get("riskTolerance", 0.35)), 0.0, 1.0, 0.05, func(value): return "%d%%" % int(round(value * 100.0))))
	rules_box.add_child(_policy_slider("최대 스트레스", "넘으면 회복 활동으로 전환", "maxStress", float(policy.get("maxStress", 72.0)), 35.0, 95.0, 1.0, func(value): return "%d" % int(value)))
	rules_box.add_child(_policy_slider("최소 보유금", "이 아래로 쓰는 활동은 피함", "reserveGoldValue", _reserve_gold_number(), 0.0, 3000.0, 100.0, func(value): return "%s G" % _format_number(value)))
	rules.add_child(rules_box)
	body.add_child(rules)

	body.add_child(_section_heading("금지 태그", "자동 후보에서 빼요."))
	_add_tip(body, "bannedTags")
	var tags := [
		{"id": "risk", "name": "고위험"}, {"id": "combat", "name": "전투"},
		{"id": "social", "name": "사교"}, {"id": "costly", "name": "고비용"},
		{"id": "outdoor", "name": "야외"}, {"id": "performance", "name": "공연"},
	]
	var banned: Array = policy.get("bannedTags", [])
	var tag_grid := GridContainer.new()
	tag_grid.columns = 2
	tag_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	tag_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
	for tag in tags:
		var active := banned.has(tag["id"])
		var tag_button := _button("제외 · %s" % tag["name"] if active else str(tag["name"]), _toggle_banned_tag.bind(str(tag["id"])), "danger" if active else "secondary", 48.0, "ban_%s" % tag["id"])
		if active:
			tag_button.icon = _icon_texture("lock")
		tag_grid.add_child(tag_button)
	body.add_child(tag_grid)

	var note := _card("transparent")
	note.add_child(_label("바꾼 방향은 진행 중인 활동을 멈추지 않고 다음 선택부터 적용돼요.", 16, PixelTokens.INK_MUTED))
	body.add_child(note)
	return page["scroll"]


func _build_activity_page() -> Control:
	var page := _page_scroll()
	var body: VBoxContainer = page["body"]

	var categories := [
		{"id": "education", "name": "학습"}, {"id": "job", "name": "알바"}, {"id": "rest", "name": "휴식"},
		{"id": "adventure", "name": "모험"}, {"id": "challenge", "name": "시험"},
	]
	var category_row := HBoxContainer.new()
	category_row.add_theme_constant_override("separation", PixelTokens.GAP)
	# 열린 활동이 있는 분류만 보인다. 고른 분류가 아직 없으면 첫 분류로 돌아간다.
	var open_counts := {}
	for activity in _activities:
		if typeof(activity) == TYPE_DICTIONARY and _activity_open(activity):
			open_counts[_activity_kind(activity)] = int(open_counts.get(_activity_kind(activity), 0)) + 1
	if not open_counts.has(_activity_filter):
		_activity_filter = "education"
	for category in categories:
		var category_id := str(category["id"])
		var count := int(open_counts.get(category_id, 0))
		if count == 0:
			continue
		var tab := _button("%s %d" % [category["name"], count], _select_activity_filter.bind(category_id), "gold" if category_id == _activity_filter else "secondary", 48.0, "filter_%s" % category_id)
		tab.theme_type_variation = "PixelButtonCompactGold" if category_id == _activity_filter else "PixelButtonCompactSecondary"
		# 선택한 분류는 색과 함께 눌린(들어간) 모양으로도 구분한다.
		tab.toggle_mode = true
		tab.button_pressed = category_id == _activity_filter
		category_row.add_child(tab)
	body.add_child(category_row)
	category_row.resized.connect(_layout_even_row.bind(category_row))
	_add_tip(body, "challenge")

	var automatic := _card("gold")
	var automatic_box := VBoxContainer.new()
	automatic_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	var recommend_row := HBoxContainer.new()
	recommend_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	recommend_row.add_child(_icon(_activity_icon_name()))
	var recommend_label := _label("추천 · %s" % _current_activity_name(), 16, PixelTokens.INK)
	recommend_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	recommend_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	recommend_row.add_child(recommend_label)
	automatic_box.add_child(recommend_row)
	var reason := _label(_planner_reason(), 16, PixelTokens.INK_MUTED)
	reason.autowrap_mode = TextServer.AUTOWRAP_OFF
	reason.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	automatic_box.add_child(reason)
	var run_recommended := _button("추천 활동 즉시 실행", _complete_current_activity, "primary", 48.0, "run_recommended")
	run_recommended.icon = _icon_texture("play")
	automatic_box.add_child(run_recommended)
	automatic.add_child(automatic_box)
	body.add_child(automatic)

	var queued: Array = _read(["activityQueue"], [])
	if not queued.is_empty():
		var queue_card := _card("transparent")
		var queue_box := VBoxContainer.new()
		queue_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		queue_box.add_child(_label("자동 큐 · %d건" % queued.size(), 16, PixelTokens.INK))
		for queue_index in range(mini(5, queued.size())):
			var queue_row := HBoxContainer.new()
			queue_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
			var queue_name := _label("%d. %s" % [queue_index + 1, _activity_name_by_id(str(queued[queue_index]))], 16, PixelTokens.INK)
			queue_name.autowrap_mode = TextServer.AUTOWRAP_OFF
			queue_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			queue_row.add_child(queue_name)
			for move in [{"text": "위", "delta": -1, "disabled": queue_index == 0}, {"text": "아래", "delta": 1, "disabled": queue_index == queued.size() - 1}]:
				var move_button := _button(str(move["text"]), _move_queued_activity.bind(queue_index, int(move["delta"])), "secondary", 44.0)
				move_button.theme_type_variation = "PixelButtonCompactSecondary"
				move_button.custom_minimum_size.x = 52.0
				move_button.size_flags_horizontal = Control.SIZE_SHRINK_END
				move_button.disabled = bool(move["disabled"])
				queue_row.add_child(move_button)
			var remove := _button("삭제", _remove_queued_activity.bind(queue_index), "danger", 44.0)
			remove.theme_type_variation = "PixelButtonDanger"
			remove.custom_minimum_size.x = 60.0
			remove.size_flags_horizontal = Control.SIZE_SHRINK_END
			queue_row.add_child(remove)
			queue_box.add_child(queue_row)
		if queued.size() > 5:
			queue_box.add_child(_label("외 %d건" % (queued.size() - 5), 16, PixelTokens.INK_MUTED))
		queue_box.add_child(_button("자동 큐 모두 비우기", _clear_activity_queue, "secondary"))
		queue_card.add_child(queue_box)
		body.add_child(queue_card)

	var list := _card("window")
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	var visible_count := 0
	for activity in _activities:
		if _activity_kind(activity) != _activity_filter or not _activity_open(activity):
			continue
		list_box.add_child(_activity_card(activity))
		visible_count += 1
		if visible_count >= 15:
			break
	if visible_count == 0:
		list_box.add_child(_label("세계 티어나 시즌 조건을 달성하면 열려요.", 16, PixelTokens.INK_MUTED))
	if _unlock_teaser_place() == "activity":
		list_box.add_child(_unlock_teaser_row())
	list.add_child(list_box)
	body.add_child(list)
	return page["scroll"]


# 활동 한 줄: 아이콘, 이름, 숙련, 비용·에너지·스트레스(또는 잠금 이유), 1회 버튼. 행을 누르면 상세 시트.
func _activity_card(activity: Dictionary) -> Control:
	var activity_id := str(activity.get("id", ""))
	var lock_reason := _activity_lock_reason(activity_id)
	var current := activity_id == str(_read(["activeTask", "activityId"], ""))
	var row_panel := _card("selected" if current else "transparent")
	row_panel.set_meta("activity_id", activity_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP)
	row_panel.add_child(row)

	var info := _button("", _open_activity_detail.bind(activity_id), "secondary", 52.0, "activity_detail_%s" % activity_id)
	info.theme_type_variation = "PixelRowButton"
	info.tooltip_text = "%s 상세" % str(activity.get("name", activity_id))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var info_box := HBoxContainer.new()
	info_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	info.add_child(info_box)
	var locked := not lock_reason.is_empty() and not _activity_in_progress(activity_id)
	var kind_icon := _icon("lock" if locked else _kind_icon_name(_activity_kind(activity)))
	info_box.add_child(kind_icon)
	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 4)
	info_box.add_child(text_box)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label(str(activity.get("name", activity_id)), 16, PixelTokens.INK_MUTED if locked else PixelTokens.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)
	var mastery_level := int(_read(["mastery", activity_id], 0))
	if mastery_level > 0:
		var mastery_label := _label("숙련 %d" % mastery_level, 16, PixelTokens.INK_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		mastery_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		mastery_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		mastery_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_row.add_child(mastery_label)
	text_box.add_child(title_row)
	var conflicts := _expedition_conflicts(activity_id) if lock_reason.is_empty() else []
	if not lock_reason.is_empty():
		var lock_label := _lock_reason_label(activity_id, lock_reason)
		lock_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		lock_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(lock_label)
	elif not conflicts.is_empty():
		var skip_label := _label(_expedition_conflict_text(conflicts, false), 16, PixelTokens.ACCENT)
		skip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		skip_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		skip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(skip_label)
	else:
		text_box.add_child(_activity_facts(activity))
	info.custom_minimum_size.y = 52.0

	var action := _button("1회", _run_activity.bind(activity_id, _conflict_ids(conflicts) if _activity_kind(activity) == "adventure" else null), "primary", 48.0, "activity_run_%s" % activity_id)
	action.custom_minimum_size.x = 60.0
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.tooltip_text = "%s 1회 실행" % str(activity.get("name", activity_id))
	action.add_to_group("critical_cta")
	action.disabled = not lock_reason.is_empty()
	row.add_child(action)
	return row_panel


# 비용(또는 보수)·에너지·스트레스 변화를 아이콘과 숫자로 한 줄에 보여 준다.
# 지금 세계 티어의 실제 비용·기본 보수(BigValue). 엔진이 없으면(대체 상태) 데이터의 기본값.
func _activity_tier_value(activity_id: String, key: String) -> Dictionary:
	if _engine != null and _engine.has_method("activity_tier_values"):
		var values: Dictionary = _engine.call("activity_tier_values", activity_id, int(_state.get("worldTier", 1))) as Dictionary
		return values.get(key, {"mantissa": 0, "exponent": 0}) as Dictionary
	var base_key := "baseCost" if key == "cost" else "baseReward"
	return {"mantissa": float(_activity_by_id(activity_id).get(base_key, 0.0)), "exponent": 0}


func _activity_facts(activity: Dictionary) -> Control:
	var facts := HBoxContainer.new()
	facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	facts.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	var activity_id := str(activity.get("id", ""))
	var cost := _big_to_number(_activity_tier_value(activity_id, "cost")) if not activity_id.is_empty() else float(activity.get("baseCost", 0.0))
	var reward := _big_to_number(_activity_tier_value(activity_id, "reward")) if not activity_id.is_empty() else float(activity.get("baseReward", 0.0))
	var entries := [
		["coin", ("-%s" % _format_number(cost)) if cost > 0.0 else (("+%s" % _format_number(reward)) if reward > 0.0 else "0"), PixelTokens.NEGATIVE if cost > 0.0 else PixelTokens.POSITIVE],
		["energy", "%+d" % int(activity.get("energyDelta", 0)), PixelTokens.INK],
		["stress", "%+d" % int(activity.get("stressDelta", 0)), PixelTokens.INK],
	]
	for entry in entries:
		facts.add_child(_icon(str(entry[0])))
		var value := _label(str(entry[1]), 16, entry[2])
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		value.custom_minimum_size.x = 52.0
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		facts.add_child(value)
	return facts


func _open_activity_detail(activity_id: String) -> void:
	_detail_activity_id = activity_id
	_open_sheet("activity_detail")


func _build_activity_detail_sheet(body: VBoxContainer) -> void:
	var activity := _activity_by_id(_detail_activity_id)
	if activity.is_empty():
		body.add_child(_label("활동 정보를 찾을 수 없어요.", 16, PixelTokens.INK_MUTED))
		return
	var lock_reason := _activity_lock_reason(_detail_activity_id)
	var card := _card("window")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", PixelTokens.GAP)
	box.add_child(_label(str(activity.get("description", "")), 16, PixelTokens.INK))
	box.add_child(_activity_facts(activity))
	var primary_stat := str(activity.get("primaryStat", ""))
	if STAT_LABELS.has(primary_stat):
		box.add_child(_label("주 성장 · %s" % STAT_LABELS[primary_stat], 16, PixelTokens.POSITIVE))
	box.add_child(_label("숙련 %d" % int(_read(["mastery", _detail_activity_id], 0)), 16, PixelTokens.INK_MUTED))
	var conflicts := _expedition_conflicts(_detail_activity_id) if lock_reason.is_empty() else []
	if not lock_reason.is_empty():
		box.add_child(_lock_reason_label(_detail_activity_id, lock_reason))
	elif not conflicts.is_empty():
		var skip_line := _label(_expedition_conflict_text(conflicts, true), 16, PixelTokens.ACCENT)
		PixelText.wrap_at_spaces(skip_line)
		box.add_child(skip_line)
	card.add_child(box)
	body.add_child(card)
	var run := _button("시험 빠지고 1회" if not conflicts.is_empty() else "이 활동 1회", _run_activity_from_detail.bind(_detail_activity_id, _conflict_ids(conflicts) if _activity_kind(activity) == "adventure" else null), "primary", 52.0, "detail_run")
	run.icon = _icon_texture("play")
	run.disabled = not lock_reason.is_empty()
	body.add_child(run)
	var queue := _button("자동 큐 +", _queue_activity.bind(_detail_activity_id), "secondary", 48.0, "detail_queue")
	queue.disabled = not lock_reason.is_empty()
	body.add_child(queue)
	# 자동 진행은 시험 일정을 지키므로, 고를 날이 없는 원정은 자동 큐에 넣어도 끝내 실행되지 않는다.
	if lock_reason.is_empty() and _activity_kind(activity) == "adventure" and _schedule_free_slot(_detail_activity_id) < 0:
		queue.disabled = true
		var queue_reason := _label("자동 진행은 시험을 지켜서 이 원정을 고를 날이 없어요. 직접 출발하면 겹친 시험에 빠져요.", 16, PixelTokens.INK_MUTED)
		PixelText.wrap_at_spaces(queue_reason)
		body.add_child(queue_reason)


func _run_activity_from_detail(activity_id: String, shown_conflicts: Variant = null) -> void:
	# 시트를 닫기 전에 확인해야 바뀐 안내를 같은 시트에서 다시 보여 줄 수 있다.
	if _expedition_conflicts_changed(activity_id, shown_conflicts):
		_open_sheet("activity_detail")
		_show_toast(EXPEDITION_SCHEDULE_CHANGED)
		return
	_close_sheet()
	_run_activity(activity_id)


func _build_growth_page() -> Control:
	var page := _page_scroll()
	var body: VBoxContainer = page["body"]

	var summary := _card("gold")
	var summary_box := HBoxContainer.new()
	summary_box.add_theme_constant_override("separation", PixelTokens.GAP)
	summary_box.add_child(_resource_card("세계 티어", "%d" % int(_state.get("worldTier", 1)), PixelTokens.GOLD))
	summary_box.add_child(_resource_card("명성", _format_big(_read(["bigValues", "renown"], {"mantissa": 0, "exponent": 0})), PixelTokens.GOLD))
	summary_box.add_child(_resource_card("칭호", "%d" % _career_title_count(), PixelTokens.GOLD))
	summary.add_child(summary_box)
	body.add_child(summary)

	body.add_child(_section_heading("능력치", "막대는 다음 100까지의 진행도예요."))
	_add_tip(body, "growth")
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	stats_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
	for stat_id in STAT_LABELS:
		stats_grid.add_child(_stat_card(str(STAT_LABELS[stat_id]), float(_read(["stats", stat_id], 0.0))))
	body.add_child(stats_grid)

	if not _feature_open("shop"):
		_add_growth_mastery(body)
		return page["scroll"]
	body.add_child(_section_heading("장비", "누르면 상점에서 바꿀 수 있어요."))
	var equipment_grid := GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	equipment_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
	var slots := {"outfit": "의상", "weapon": "무기", "armor": "방어구", "accessory": "장신구"}
	for slot_id in slots:
		var equipped = _read(["equipment", slot_id], null)
		var display := "비어 있음" if equipped == null else _item_display_name(str(equipped))
		var level := _inventory_enhancement_level(str(equipped)) if equipped != null else 0
		var slot_button := _button("%s%s\n%s" % [slots[slot_id], " Lv.%d" % level if level > 0 else "", display], _open_sheet.bind("shop"), "secondary", 64.0, "slot_%s" % slot_id)
		slot_button.icon = _icon_texture("slot_" + slot_id)
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		equipment_grid.add_child(slot_button)
	body.add_child(equipment_grid)

	body.add_child(_section_heading("관계", "선물로 관계를 높일 수 있어요."))
	_add_tip(body, "relations")
	var relations := _card("window")
	var relation_box := VBoxContainer.new()
	relation_box.add_theme_constant_override("separation", PixelTokens.GAP)
	for relation_id in RELATION_LABELS:
		var relation_value := float(_read(["relations", relation_id], 0.0))
		var relation_row := HBoxContainer.new()
		relation_row.add_theme_constant_override("separation", PixelTokens.GAP)
		var relation_text := VBoxContainer.new()
		relation_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		relation_text.add_theme_constant_override("separation", 4)
		var relation_label := _label("%s · %d / 1000" % [RELATION_LABELS[relation_id], int(relation_value)], 16, PixelTokens.INK)
		relation_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		relation_text.add_child(relation_label)
		relation_text.add_child(_gauge("reputation", relation_value / 1000.0))
		relation_row.add_child(relation_text)
		var gift := _button("선물", _open_shop_for_gift.bind(str(relation_id)), "secondary", 44.0, "gift_%s" % relation_id)
		gift.theme_type_variation = "PixelButtonCompactSecondary"
		gift.custom_minimum_size.x = 64.0
		gift.size_flags_horizontal = Control.SIZE_SHRINK_END
		relation_row.add_child(gift)
		relation_box.add_child(relation_row)
	relations.add_child(relation_box)
	body.add_child(relations)

	_add_growth_mastery(body)
	return page["scroll"]


func _add_growth_mastery(body: VBoxContainer) -> void:
	body.add_child(_section_heading("활동 숙련", "10·25·50·100 뒤로는 100마다 효율이 올라요."))
	var mastery: Dictionary = _read(["mastery"], {})
	var mastery_card := _card("transparent")
	var mastery_box := VBoxContainer.new()
	mastery_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	if mastery.is_empty():
		mastery_box.add_child(_label("활동을 마치면 숙련이 쌓여요.", 16, PixelTokens.INK_MUTED))
	for activity_id in mastery:
		var mastery_row := HBoxContainer.new()
		var mastery_name := _label(_activity_name_by_id(str(activity_id)), 16, PixelTokens.INK)
		mastery_name.autowrap_mode = TextServer.AUTOWRAP_OFF
		mastery_row.add_child(mastery_name)
		mastery_row.add_child(_chip("Lv. %d" % int(mastery[activity_id]), PixelTokens.GOLD))
		mastery_box.add_child(mastery_row)
	mastery_card.add_child(mastery_box)
	body.add_child(mastery_card)


func _build_record_page() -> Control:
	var page := _page_scroll()
	var body: VBoxContainer = page["body"]
	body.add_child(_section_heading("시즌 기록", "끝나지 않는 성장. 시즌마다 칭호와 새 세계가 열려요."))
	_add_tip(body, "record")

	var season_card := _card("gold")
	var season_box := VBoxContainer.new()
	season_box.add_theme_constant_override("separation", PixelTokens.GAP)
	season_box.add_child(_label("%d연차 · %d시즌" % [int(_read(["time", "year"], 1)), int(_read(["time", "season"], 1))], 24, PixelTokens.INK))
	var slots_per_season := maxi(1, _config_int("slotsPerSeason", 28))
	season_box.add_child(_gauge("reputation", float(_season_slot()) / float(slots_per_season)))
	season_box.add_child(_label("다음 심사까지 %d회 · 종료나 초기화 없음" % (slots_per_season - _season_slot()), 16, PixelTokens.INK_MUTED))
	season_card.add_child(season_box)
	body.add_child(season_card)
	var season_history: Array = _read(["seasonHistory"], [])
	if not season_history.is_empty() and typeof(season_history.back()) == TYPE_DICTIONARY:
		var latest_review: Dictionary = season_history.back() as Dictionary
		var review_card := _card("raised")
		var review_box := VBoxContainer.new()
		review_box.add_theme_constant_override("separation", 4)
		review_box.add_child(_label("최근 심사 · %d연차 %d시즌" % [int(latest_review.get("year", 1)), int(latest_review.get("season", 1))], 16, PixelTokens.INK))
		review_box.add_child(_label("명성 +%d · 정책 일치 %d%% · 도전 승리 %d · 계약 %d" % [
			int(latest_review.get("renownGained", 0)), int(float(latest_review.get("policyFit", 0.0)) * 100.0),
			int(latest_review.get("challengeWins", 0)), int(latest_review.get("completedContracts", 0))
		], 16, PixelTokens.INK_MUTED))
		review_card.add_child(review_box)
		body.add_child(review_card)

	var event_count := _event_inbox().size()
	var record_actions := GridContainer.new()
	record_actions.columns = 2
	record_actions.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	record_actions.add_theme_constant_override("v_separation", PixelTokens.GAP)
	for action in [
		["월드·라이벌", "world", "primary", "record_world", "world"],
		["이벤트 %d건" % event_count, "event", "gold" if event_count > 0 else "secondary", "record_event", "event"],
		["상점", "shop", "secondary", "record_shop", "coin"],
		["설정", "settings", "secondary", "record_settings", "preset_custom"],
	]:
		if str(action[1]) != "settings" and not _feature_open(str(action[1]) if str(action[1]) != "event" else "events"):
			continue
		var record_button := _button(str(action[0]), _open_sheet.bind(str(action[1])), str(action[2]), 48.0, str(action[3]))
		record_button.icon = _icon_texture(str(action[4]))
		record_actions.add_child(record_button)
	_fit_grid_columns(record_actions)
	body.add_child(record_actions)

	body.add_child(_section_heading("주간 계약", "지금 열린 활동으로 달성할 수 있는 목표예요."))
	_add_tip(body, "contracts")
	var contracts: Array = _read(["generatedContent", "contracts"], [])
	var pinned_contract_id := str(_read(["generatedContent", "pinnedContractId"], ""))
	for contract in contracts:
		if typeof(contract) != TYPE_DICTIONARY:
			continue
		var contract_card := _card("raised")
		var contract_box := VBoxContainer.new()
		contract_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		var contract_top := HBoxContainer.new()
		contract_top.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		var contract_name := _label(str(contract.get("name", "주간 계약")), 16, PixelTokens.INK)
		contract_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		contract_top.add_child(contract_name)
		contract_top.add_child(_chip("%s G" % _format_big(contract.get("reward", {"mantissa": 0, "exponent": 0})), PixelTokens.GOLD))
		contract_box.add_child(contract_top)
		contract_box.add_child(_label(str(contract.get("description", "현재 성장 경로로 달성 가능한 계약입니다.")), 16, PixelTokens.INK_MUTED))
		var contract_meta: Array[String] = []
		var contract_region = contract.get("region", {})
		if typeof(contract_region) == TYPE_DICTIONARY and not str(contract_region.get("name", "")).is_empty():
			contract_meta.append(str(contract_region.get("name", "")))
		for modifier in contract.get("modifiers", []):
			contract_meta.append(_contract_modifier_name(str(modifier)))
		var bonus = contract.get("bonusObjective", {})
		if typeof(bonus) == TYPE_DICTIONARY and not str(bonus.get("name", "")).is_empty():
			contract_meta.append("보너스: %s" % str(bonus.get("name", "")))
		if not contract_meta.is_empty():
			contract_box.add_child(_label(" · ".join(contract_meta), 16, PixelTokens.POSITIVE))
		contract_box.add_child(_gauge("stat", float(contract.get("progress", 0)) / maxf(1.0, float(contract.get("target", 1)))))
		var contract_id := str(contract.get("id", ""))
		var contract_status := str(contract.get("status", "active"))
		contract_box.add_child(_label("%d / %d · %s" % [
			int(contract.get("progress", 0)), int(contract.get("target", 1)),
			"보상 자동 수령 완료" if contract_status == "completed" else ("고정 중" if pinned_contract_id == contract_id else "진행 중")
		], 16, PixelTokens.INK_MUTED))
		if contract_status == "active":
			contract_box.add_child(_button("고정 해제" if pinned_contract_id == contract_id else "이 계약 고정", _pin_contract.bind("" if pinned_contract_id == contract_id else contract_id), "gold" if pinned_contract_id == contract_id else "secondary", 48.0, "contract_pin_%s" % contract_id))
		contract_card.add_child(contract_box)
		body.add_child(contract_card)

	body.add_child(_section_heading("진로 칭호", "38개 진로는 엔딩이 아니라 반복해 키우는 전문 분야예요."))
	var titles: Dictionary = _read(["careerTitles"], {})
	if titles.is_empty():
		var title_empty := _card("transparent")
		title_empty.add_child(_label("첫 시즌 심사에서 가까운 진로 세 개가 제안됩니다.", 16, PixelTokens.INK_MUTED))
		body.add_child(title_empty)
	else:
		# 칭호 격자: 이름과 별(5개까지), 5성을 넘으면 명인 단계 글자
		var title_grid := GridContainer.new()
		title_grid.columns = 2
		title_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
		title_grid.add_theme_constant_override("v_separation", PixelTokens.GAP)
		for title_id in titles:
			var title_data = titles[title_id]
			var stars := int(title_data.get("stars", 1)) if typeof(title_data) == TYPE_DICTIONARY else int(title_data)
			var title_card := _card("gold")
			var title_box := VBoxContainer.new()
			title_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
			var name_row := HBoxContainer.new()
			name_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
			name_row.add_child(_icon("record"))
			var title_label := _label(_career_display_name(str(title_id), title_data), 16, PixelTokens.INK)
			title_label.max_lines_visible = 2
			name_row.add_child(title_label)
			title_box.add_child(name_row)
			var star_row := HBoxContainer.new()
			star_row.add_theme_constant_override("separation", 2)
			for star_index in mini(5, maxi(1, stars)):
				star_row.add_child(_icon("reputation"))
			if stars > 5:
				var master := _label("명인 +%d" % (stars - 5), 16, PixelTokens.ACCENT)
				master.autowrap_mode = TextServer.AUTOWRAP_OFF
				star_row.add_child(master)
			star_row.tooltip_text = _career_rank(stars)
			title_box.add_child(star_row)
			title_card.add_child(title_box)
			title_grid.add_child(title_card)
		body.add_child(title_grid)

	if not season_history.is_empty() and typeof(season_history.back()) == TYPE_DICTIONARY:
		var near_titles: Array = (season_history.back() as Dictionary).get("nearTitles", []) as Array
		if not near_titles.is_empty():
			body.add_child(_section_heading("가까운 진로", "다음 심사에서 노릴 만한 세 분야예요."))
			for near in near_titles:
				if typeof(near) != TYPE_DICTIONARY:
					continue
				var near_card := _card("transparent")
				var near_box := VBoxContainer.new()
				near_box.add_theme_constant_override("separation", 4)
				near_box.add_child(_label("%s · %d%%" % [str(near.get("name", near.get("id", "진로"))), int(float(near.get("progress", 0.0)) * 100.0)], 16, PixelTokens.INK))
				near_box.add_child(_gauge("stat", float(near.get("progress", 0.0))))
				var missing_label := _label("부족 · %s" % ", ".join(near.get("missing", [])), 16, PixelTokens.INK_MUTED)
				PixelText.wrap_at_spaces(missing_label)
				near_box.add_child(missing_label)
				near_card.add_child(near_box)
				body.add_child(near_card)

	var event_history: Dictionary = _read(["eventHistory"], {})
	body.add_child(_section_heading("이벤트 도감 · %d / 26" % event_history.size(), "해결한 사건과 마지막 선택이 남아요."))
	if event_history.is_empty():
		var event_empty := _card("transparent")
		event_empty.add_child(_label("아직 해결한 이벤트가 없습니다.", 16, PixelTokens.INK_MUTED))
		body.add_child(event_empty)
	else:
		for event_id in event_history:
			var history_entry: Dictionary = event_history[event_id] as Dictionary
			var history_card := _card("transparent")
			history_card.add_child(_label("%s · %d회 · 마지막 선택 %s" % [
				_event_display_name(str(event_id)), int(history_entry.get("count", 0)), _event_choice_display_name(str(event_id), str(history_entry.get("lastChoice", "-")))
			], 16, PixelTokens.INK_MUTED))
			body.add_child(history_card)
	return page["scroll"]


func _open_sheet(kind: String) -> void:
	# 시트를 새로 열 때(같은 시트 다시 그리기가 아닐 때) 그 시트의 안내 차례를 새로 시작한다.
	if not _find_open_sheet(kind):
		_tips_showing.erase(kind)
	# 아직 열리지 않은 기능의 시트는 열지 않는다(버튼은 숨겨져 있어 평소에는 오지 않는다).
	var sheet_feature := str({"world": "world", "shop": "shop", "event": "events"}.get(kind, ""))
	if not sheet_feature.is_empty() and not _feature_open(sheet_feature):
		_show_toast("아직 열리지 않았어요. %s" % _unlock_teaser_sentence())
		return
	# 같은 시트를 다시 그리면(구매·장착·도전 뒤) 스크롤 위치를 지킨다.
	var keep: Node = null
	var keep_scroll := 0
	if _modal_layer != null:
		for child in _modal_layer.get_children():
			if not child.is_queued_for_deletion() and str(child.get_meta("screen_id", "")) == kind:
				for found in child.find_children("*", "ScrollContainer", true, false):
					keep_scroll = (found as ScrollContainer).scroll_vertical
					break
				if keep_scroll > 0:
					keep = child
	_close_sheet(keep)
	_refresh_chrome()
	_track_event(&"screen_view", {"screen": kind})
	var overlay := ColorRect.new()
	overlay.name = "Screen_%s" % kind.capitalize()
	overlay.set_meta("screen_id", kind)
	overlay.color = PixelTokens.DIM
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(overlay)
	_raise_feedback_layer()

	var sheet := PanelContainer.new()
	sheet.name = "Sheet"
	sheet.anchor_left = 0.0
	sheet.anchor_right = 1.0
	# 화면 높이의 17% 아래에서 시작하되 2px 격자에 맞춘다.
	sheet.anchor_top = 0.0
	sheet.offset_top = floorf(_modal_layer.size.y * 0.17 / 2.0) * 2.0
	sheet.anchor_bottom = 1.0
	sheet.offset_left = 6.0
	sheet.offset_right = -6.0
	sheet.offset_bottom = 0.0
	sheet.theme_type_variation = PixelTheme.panel_variation("sheet")
	overlay.add_child(sheet)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	sheet.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_text.add_theme_constant_override("separation", 0)
	var sheet_info := _sheet_title(kind)
	heading_text.add_child(_label(str(sheet_info[0]), 24, PixelTokens.INK))
	heading_text.add_child(_label(str(sheet_info[1]), 16, PixelTokens.INK_MUTED))
	heading.add_child(heading_text)
	var close_button := _button("닫기", _close_sheet, "ghost", 48.0, "sheet_close")
	close_button.custom_minimum_size.x = 72.0
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	heading.add_child(close_button)
	column.add_child(heading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	match kind:
		"menu": _build_menu_sheet(body)
		"world": _build_world_sheet(body)
		"shop": _build_shop_sheet(body)
		"settings": _build_settings_sheet(body)
		"offline": _build_offline_sheet(body)
		"event": _build_event_sheet(body)
		"profile": _build_profile_sheet(body)
		"continue": _build_continue_sheet(body)
		"reset": _build_reset_sheet(body)
		"activity_detail": _build_activity_detail_sheet(body)
		_: _build_menu_sheet(body)
	_ink_headings(body)
	if keep != null:
		overlay.modulate.a = 0.0
		_swap_in_after_layout(overlay, scroll, keep_scroll, [keep])


func _close_sheet(keep: Node = null) -> void:
	if _modal_layer == null:
		return
	for child in _modal_layer.get_children():
		if child != _toast_panel and child != _result_feedback_layer and child != keep:
			child.queue_free()


# 손가락이 눌려 있거나 목록이 관성으로 움직이는 중이면 자동 진행의 화면 갱신을 미룬다.
func _list_in_motion() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _scroll_still_frames < 6


func _track_scroll_motion() -> void:
	var value := -1
	if _content_host != null:
		for child in _content_host.get_children():
			if child is ScrollContainer and not child.is_queued_for_deletion():
				value = (child as ScrollContainer).scroll_vertical
	if value != _scroll_probe_value:
		_scroll_probe_value = value
		_scroll_still_frames = 0
	else:
		_scroll_still_frames += 1


# 결과 창은 시트보다 위에 그려지므로 입력도 시트보다 먼저 받도록 모달 층의 마지막 자식으로 둔다.
func _raise_feedback_layer() -> void:
	if _modal_layer != null and _result_feedback_layer != null and _result_feedback_layer.get_parent() == _modal_layer:
		_modal_layer.move_child(_result_feedback_layer, _modal_layer.get_child_count() - 1)


# 새 페이지·시트를 배치가 끝날 때까지 숨겼다가 같은 스크롤 위치로 보여 주고 옛 것을 지운다(한 프레임 맨 위 깜빡임 방지).
func _swap_in_after_layout(shown: CanvasItem, scroll: ScrollContainer, value: int, old_nodes: Array) -> void:
	await get_tree().process_frame
	# 교체 직전의 옛 목록 위치를 다시 읽어 그 사이 움직임도 이어받는다.
	for old in old_nodes:
		if is_instance_valid(old):
			var old_scroll := old as ScrollContainer if old is ScrollContainer else null
			if old_scroll == null:
				for found in (old as Node).find_children("*", "ScrollContainer", true, false):
					old_scroll = found as ScrollContainer
					break
			if old_scroll != null:
				value = old_scroll.scroll_vertical
				break
	if is_instance_valid(scroll):
		scroll.scroll_vertical = value
	if is_instance_valid(shown):
		shown.modulate.a = 1.0
	for old in old_nodes:
		if is_instance_valid(old):
			(old as Node).queue_free()


func _sheet_title(kind: String) -> Array:
	match kind:
		"world": return ["월드", "모험·시험·스포츠·대회·라이벌 리그"]
		"shop": return ["상점과 인벤토리", "장비와 소비품을 성장 방향에 맞춰 준비하세요."]
		"settings": return ["설정", "접근성·사운드·자동 진행·데이터"]
		"offline": return ["오프라인 정산", "꺼져 있던 동안 %d초마다 1회, 최대 %s까지 이어서 진행해요." % [
			maxi(1, _config_int("offlineSecondsPerSlot", 60)),
			_duration_label(_config_int("offlineCapSeconds", 28800)),
		]]
		"event": return ["이벤트", "자동 성장은 멈추지 않으며 선택은 나중에 결정해도 됩니다."]
		"profile": return ["새 수련생", "이름과 첫 성장 방향을 정합니다."]
		"continue": return ["이어하기", "기기에 저장된 최신 수련 기록을 불러옵니다."]
		"reset": return ["데이터 초기화", "현재 수련 기록을 지우고 처음부터 시작합니다."]
		"activity_detail": return [_activity_name_by_id(_detail_activity_id), "활동 상세"]
		_: return ["아카데미 메뉴", "모든 기능으로 이동해요."]


func _build_menu_sheet(body: VBoxContainer) -> void:
	var summary := _card("gold")
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 6)
	summary_box.add_child(_label("%s · %s 성장" % [str(_state.get("traineeName", "수련생")), _preset_name(_policy_preset())], 20, PixelTokens.ACCENT))
	summary_box.add_child(_label("%d연차 %d시즌 · 세계 티어 %d" % [int(_read(["time", "year"], 1)), int(_read(["time", "season"], 1)), int(_state.get("worldTier", 1))], 16, PixelTokens.INK_MUTED))
	summary.add_child(summary_box)
	body.add_child(summary)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	grid.add_theme_constant_override("v_separation", 8)
	for entry in [
		["이어하기", _replace_sheet.bind("continue"), "primary", "menu_continue", "play"],
		["새 수련생", _replace_sheet.bind("profile"), "secondary", "menu_profile", "preset_balanced"],
		["월드", _replace_sheet.bind("world"), "gold", "menu_world", "world"],
		["상점", _replace_sheet.bind("shop"), "secondary", "menu_shop", "coin"],
		["오프라인", _replace_sheet.bind("offline"), "secondary", "menu_offline", "moon"],
		["이벤트", _replace_sheet.bind("event"), "secondary", "menu_event", "event"],
		["설정", _replace_sheet.bind("settings"), "secondary", "menu_settings", "preset_custom"],
		["지금 저장", _save_game, "secondary", "menu_save", "record"],
	]:
		var menu_feature := str({"menu_world": "world", "menu_shop": "shop", "menu_event": "events"}.get(str(entry[3]), ""))
		if not menu_feature.is_empty() and not _feature_open(menu_feature):
			continue
		var menu_button := _button(str(entry[0]), entry[1], str(entry[2]), 48.0, str(entry[3]))
		menu_button.icon = _icon_texture(str(entry[4]))
		grid.add_child(menu_button)
	body.add_child(grid)

	var guide := _card("transparent")
	guide.add_child(_label("일상 성장은 아래 탭에서, 월드와 상점은 여기서 열어요." if _feature_open("world") else "새 기능은 수련생이 성장하면서 하나씩 열려요.", 16, PixelTokens.INK_MUTED))
	body.add_child(guide)


func _build_world_sheet(body: VBoxContainer) -> void:
	var world_card := _card("gold")
	var world_box := VBoxContainer.new()
	world_box.add_theme_constant_override("separation", 6)
	var world_title := HBoxContainer.new()
	world_title.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	world_title.add_child(_icon("world"))
	world_title.add_child(_label("세계 티어 %d · 새벽빛 왕국" % int(_state.get("worldTier", 1)), 16, PixelTokens.INK))
	world_box.add_child(world_title)
	var league: Dictionary = _read(["challengeLeague"], {})
	if _feature_open("league"):
		world_box.add_child(_label("리그 %d단계 · 이번 시즌 %d승 %d패 · 최고 %.1f" % [
			int(league.get("leagueTier", 1)), int(league.get("seasonWins", 0)), int(league.get("seasonLosses", 0)), float(league.get("bestScore", 0.0))
		], 16, PixelTokens.INK_MUTED))
	world_box.add_child(_label("실패해도 경험과 다음 시도 힌트를 얻어요.", 16, PixelTokens.INK_MUTED))
	world_card.add_child(world_box)
	body.add_child(world_card)
	_add_tip(body, "world")
	var region: Dictionary = _read(["generatedContent", "region"], {})
	if not region.is_empty():
		var region_card := _card("coral")
		var region_box := VBoxContainer.new()
		region_box.add_theme_constant_override("separation", 6)
		region_box.add_child(_label(str(region.get("name", "이번 시즌 변형 지역")), 19, PixelTokens.ACCENT))
		var region_key := str(region.get("baseRegionId", region.get("templateId", "REG_DEFAULT")))
		var region_progress: Dictionary = _read(["regionProgress", region_key], {})
		var region_clears := int(region_progress.get("clearCount", 0))
		var clears_per_tier := maxi(1, _config_int("regionClearsPerTier", 3))
		region_box.add_child(_label("특성 · %s · 지역 티어 %d · 클리어 %d · 시즌 %d까지" % [
			", ".join(region.get("modifiers", [])), 1 + int(region_clears / clears_per_tier), region_clears, int(region.get("expirySeason", 1))
		], 16, PixelTokens.INK_MUTED))
		region_card.add_child(region_box)
		body.add_child(region_card)

	body.add_child(_section_heading("자동 모험", "탐색, 조우, 보스 세 단계를 자동으로 풀어요."))
	for activity in _activities:
		if typeof(activity) != TYPE_DICTIONARY or _activity_kind(activity) != "adventure":
			continue
		var adventure_id := str(activity.get("id", ""))
		body.add_child(_world_action_card(
			str(activity.get("name", adventure_id)),
			str(activity.get("description", "세 노드 자동 원정")),
			adventure_id, "원정 시작", _activity_lock_reason(adventure_id)
		))

	body.add_child(_section_heading("시험·스포츠·대회", "종목마다 보는 능력치가 달라요."))
	for activity in _activities:
		if typeof(activity) != TYPE_DICTIONARY or _activity_kind(activity) != "challenge":
			continue
		var challenge_id := str(activity.get("id", ""))
		body.add_child(_world_action_card(
			str(activity.get("name", challenge_id)),
			_challenge_weight_summary(activity),
			challenge_id, "참가하기", _activity_lock_reason(challenge_id)
		))

	if not _feature_open("league"):
		return
	body.add_child(_section_heading("라이벌 리그", "비슷한 점수의 라이벌 다섯 명과 겨뤄요."))
	_add_tip(body, "league")
	var rivals: Array = _read(["generatedContent", "rivals"], [])
	for rival in rivals:
		if typeof(rival) != TYPE_DICTIONARY:
			continue
		var rival_card := _card("coral")
		var rival_row := HBoxContainer.new()
		var rival_text := VBoxContainer.new()
		rival_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rival_text.add_child(_label(str(rival.get("name", "라이벌")), 17, PixelTokens.INK))
		rival_text.add_child(_label("%d위 · %s · 강점 %s / 약점 %s" % [
			int(rival.get("leagueRank", 1)), str(rival.get("personality", "신중함")),
			str(rival.get("strength", "균형")), str(rival.get("weakness", "균형"))
		], 16, PixelTokens.INK_MUTED))
		rival_row.add_child(rival_text)
		rival_row.add_child(_chip("점수 %d" % int(rival.get("score", 0)), PixelTokens.GOLD))
		rival_card.add_child(rival_row)
		body.add_child(rival_card)


func _build_shop_sheet(body: VBoxContainer) -> void:
	_add_tip(body, "shop")
	var wallet := _card("gold")
	var wallet_row := HBoxContainer.new()
	var wallet_label := _label("보유 골드", 17, PixelTokens.INK)
	wallet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_row.add_child(wallet_label)
	wallet_row.add_child(_label("%s G" % _format_big(_read(["bigValues", "gold"], {"mantissa": 0, "exponent": 0})), 22, PixelTokens.ACCENT))
	wallet.add_child(wallet_row)
	body.add_child(wallet)

	body.add_child(_section_heading("선물 대상", "보유 소비품을 건네 관계를 높일 대상을 선택합니다."))
	var gift_targets := GridContainer.new()
	gift_targets.columns = 2
	gift_targets.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	gift_targets.add_theme_constant_override("v_separation", 8)
	for relation_id in RELATION_LABELS:
		gift_targets.add_child(_button(
			"선택됨 · %s" % RELATION_LABELS[relation_id] if _gift_target == relation_id else str(RELATION_LABELS[relation_id]),
			_select_gift_target.bind(str(relation_id)), "primary" if _gift_target == relation_id else "ghost"
		))
	body.add_child(gift_targets)

	body.add_child(_section_heading("전체 상점 · %d종" % _items.size(), "장비는 구매 당시 세계 티어의 강화 레벨을 얻고, 소비품은 99개까지 중첩됩니다."))
	for raw_item in _items:
		if typeof(raw_item) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw_item as Dictionary
		var item_id := str(item.get("id", ""))
		var owned := _inventory_count_ui(item_id)
		var equipped_slot := _equipped_slot_for(item_id)
		var item_card := _card("transparent")
		var item_box := VBoxContainer.new()
		item_box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		var item_top := HBoxContainer.new()
		item_top.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		var category := str(item.get("category", ""))
		item_top.add_child(_icon("slot_" + category if category in ["outfit", "weapon", "armor", "accessory"] else "potion"))
		var item_name := _label("%s · %s" % [_item_category_name(category), str(item.get("name", item_id))], 16, PixelTokens.INK)
		item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_top.add_child(item_name)
		item_top.add_child(_chip("%s G" % _tier_item_price_text(item), PixelTokens.GOLD))
		item_box.add_child(item_top)
		var item_description := _label(str(item.get("description", "성장에 도움이 되는 물품입니다.")), 16, PixelTokens.INK_MUTED)
		item_description.max_lines_visible = 2
		item_box.add_child(item_description)
		var status_parts: Array[String] = []
		if owned > 0:
			status_parts.append("보유 %d" % owned)
		var enhancement := _inventory_enhancement_level(item_id)
		if enhancement > 0:
			status_parts.append("강화 Lv.%d" % enhancement)
		if not equipped_slot.is_empty():
			status_parts.append("장착 중")
		if not status_parts.is_empty():
			item_box.add_child(_label(" · ".join(status_parts), 16, PixelTokens.POSITIVE))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		if owned <= 0 or bool(item.get("stackable", false)):
			var affordable := _big_to_number(_read(["bigValues", "gold"], {"mantissa": 0, "exponent": 0})) >= _tier_item_price_number(item)
			var buy := _button("구매" if affordable else "골드 부족", _shop_action.bind(item_id), "primary" if owned <= 0 else "secondary", 48.0, "buy_%s" % item_id)
			buy.disabled = not affordable
			if not affordable:
				buy.icon = _icon_texture("lock")
			actions.add_child(buy)
		if owned > 0 and bool(item.get("stackable", false)):
			actions.add_child(_button("사용", _inventory_action.bind("use", item_id), "gold", 48.0, "use_%s" % item_id))
			actions.add_child(_button("선물", _gift_item.bind(item_id, _gift_target), "secondary"))
		elif owned > 0:
			actions.add_child(_button("해제" if not equipped_slot.is_empty() else "장착", _inventory_action.bind("unequip" if not equipped_slot.is_empty() else "equip", item_id), "gold", 48.0, "equip_%s" % item_id))
		if owned > 0:
			actions.add_child(_button("판매", _inventory_action.bind("sell", item_id), "ghost", 48.0, "sell_%s" % item_id))
		item_box.add_child(actions)
		item_card.add_child(item_box)
		body.add_child(item_card)

	var inventory_stack_max := maxi(1, _config_int("inventoryStackMax", 99))
	body.add_child(_section_heading("인벤토리", "소비품은 최대 %d개까지 중첩됩니다." % inventory_stack_max))
	var inventory: Array = _read(["inventory"], [])
	if inventory.is_empty():
		var inventory_empty := _card("transparent")
		var inventory_empty_row := HBoxContainer.new()
		inventory_empty_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		inventory_empty_row.add_child(_icon("potion"))
		inventory_empty_row.add_child(_label("보관 중인 물품이 없어요.", 16, PixelTokens.INK_MUTED))
		inventory_empty.add_child(inventory_empty_row)
		body.add_child(inventory_empty)
	else:
		for stack in inventory:
			if typeof(stack) != TYPE_DICTIONARY:
				continue
			var stack_card := _card("transparent")
			var stack_row := HBoxContainer.new()
			var stack_name := _label(_item_display_name(str(stack.get("id", "ITEM"))), 17, PixelTokens.INK)
			stack_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stack_row.add_child(stack_name)
			stack_row.add_child(_chip("%d%s" % [int(stack.get("count", 1)), " / %d" % inventory_stack_max if bool(_item_by_id(str(stack.get("id", ""))).get("stackable", false)) else ""], PixelTokens.POSITIVE))
			stack_card.add_child(stack_row)
			body.add_child(stack_card)


func _build_settings_sheet(body: VBoxContainer) -> void:
	body.add_child(_section_heading("진행", "바로 반영돼요."))
	body.add_child(_setting_toggle("자동 진행", "%s마다 다음 활동을 진행해요." % _duration_label(int(ceil(_config_float("onlineSecondsPerSlot", 5.0)))), "autoRun", _auto_running))
	body.add_child(_setting_toggle("모션 줄이기", "캐릭터 움직임과 반짝임을 멈춰요.", "reducedMotion", bool(_read(["settings", "reducedMotion"], false))))
	body.add_child(_setting_toggle("효과음", "버튼과 보상 효과음을 켜요.", "sound", bool(_read(["settings", "sound"], true))))
	body.add_child(_setting_toggle("고대비", "글자와 테두리를 더 진하게 보여 줘요.", "highContrast", bool(_read(["settings", "highContrast"], false))))

	body.add_child(_section_heading("저장과 데이터", "활동이 끝나거나 설정을 바꾸면 자동 저장돼요."))
	body.add_child(_button("지금 저장", _save_game, "primary", 48.0, "settings_save"))
	body.add_child(_button("저장 기록 이어하기", _replace_sheet.bind("continue"), "secondary", 48.0, "settings_continue"))
	body.add_child(_button("데이터 초기화", _replace_sheet.bind("reset"), "danger"))

	var policy_note := _card("transparent")
	policy_note.add_child(_label("진행은 이 기기에만 저장돼요. 광고와 결제는 없어요.", 16, PixelTokens.INK_MUTED))
	body.add_child(policy_note)


func _build_offline_sheet(body: VBoxContainer) -> void:
	var banner := TextureRect.new()
	banner.texture = PixelTheme.doubled_texture("res://assets/pixel/scenes/offline_night.png")
	banner.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(banner)
	var summary := _card("gold")
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 8)
	var pending_slots := int(_state.get("pendingOfflineSlots", 0))
	var last_summary: Dictionary = _state.get("lastOfflineSummary", {}) as Dictionary
	var settled_slots := int(last_summary.get("slotsAdvanced", 0))
	if settled_slots > 0:
		summary_box.add_child(_label("오프라인 성장 %d회 완료" % settled_slots, 26, PixelTokens.ACCENT))
		for change: String in last_summary.get("changes", []) as Array:
			# 줄어든 값(골드 지출 등)은 오름 화살표 없이 붉은 글자로 보여 준다.
			var decreased := change.contains(" -")
			var change_row := HBoxContainer.new()
			change_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
			if not decreased:
				change_row.add_child(_icon("up"))
			change_row.add_child(_label(change, 16, PixelTokens.NEGATIVE if decreased else PixelTokens.POSITIVE))
			summary_box.add_child(change_row)
		for unlock_label: String in last_summary.get("unlockLabels", []) as Array:
			var unlock_row := HBoxContainer.new()
			unlock_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
			unlock_row.add_child(_icon("plus"))
			unlock_row.add_child(_label("새로 열림 · %s" % unlock_label, 16, PixelTokens.ACCENT))
			summary_box.add_child(unlock_row)
		summary_box.add_child(_label("활동 %d건 · 시즌 심사 %d건%s" % [
			(last_summary.get("completedActivities", []) as Array).size(),
			(last_summary.get("seasonReviews", []) as Array).size(),
			" · 8시간 상한 적용" if bool(last_summary.get("capped", false)) else "",
		], 16, PixelTokens.INK_MUTED))
	else:
		summary_box.add_child(_label("정산 가능 %d회" % pending_slots, 26, PixelTokens.ACCENT))
	summary_box.add_child(_label("최대 %d회 · %s · 기기 시계를 되돌리면 0회" % [_offline_cap_slots(), _duration_label(_config_int("offlineCapSeconds", 28800))], 16, PixelTokens.INK_MUTED))
	summary.add_child(summary_box)
	body.add_child(summary)

	var rules := _card("raised")
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 8)
	rules_box.add_child(_label("정산 규칙", 18, PixelTokens.INK))
	rules_box.add_child(_label("· 저장된 진행 기록에서 그대로 이어서 계산해요", 16, PixelTokens.INK_MUTED))
	rules_box.add_child(_label("· 켜져 있을 때와 같은 규칙으로 활동을 처리해요", 16, PixelTokens.INK_MUTED))
	rules_box.add_child(_label("· 이벤트는 최대 20건까지 편지함에 보관해요", 16, PixelTokens.INK_MUTED))
	rules.add_child(rules_box)
	body.add_child(rules)

	var collect := _button("오프라인 결과 받기" if pending_slots > 0 else "받을 결과 없음", _collect_offline, "primary", 48.0, "offline_collect")
	collect.disabled = pending_slots <= 0
	if collect.disabled:
		collect.icon = _icon_texture("lock")
	collect.add_to_group("critical_cta")
	body.add_child(collect)


func _build_event_sheet(body: VBoxContainer) -> void:
	_add_tip(body, "events")
	var events := _event_inbox()
	if events.is_empty():
		var empty := _card("transparent")
		var empty_box := VBoxContainer.new()
		empty_box.add_theme_constant_override("separation", 8)
		empty_box.add_child(_icon("event"))
		empty_box.add_child(_label("대기 중인 이벤트가 없습니다.", 20, PixelTokens.INK))
		empty_box.add_child(_label("활동 해결당 최대 한 건이 도착하며 자동 진행은 멈추지 않아요.", 16, PixelTokens.INK_MUTED))
		empty.add_child(empty_box)
		body.add_child(empty)
		return
	for event in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var event_card := _card("coral")
		var event_box := VBoxContainer.new()
		event_box.add_theme_constant_override("separation", PixelTokens.GAP)
		var event_title := HBoxContainer.new()
		event_title.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		event_title.add_child(_icon("event"))
		event_title.add_child(_label(str(event.get("name", "아카데미 소식")), 24, PixelTokens.INK))
		event_box.add_child(event_title)
		event_box.add_child(_label(str(event.get("description", "새로운 선택지가 도착했습니다.")), 16, PixelTokens.INK))
		var choices: Array = event.get("choices", [])
		if choices.is_empty():
			choices = [{"id": "default", "text": "확인"}]
		for choice in choices:
			if typeof(choice) != TYPE_DICTIONARY:
				continue
			var choice_button := _button(str(choice.get("text", "선택")), _resolve_event.bind(str(event.get("id", "")), str(choice.get("id", "default"))), "primary" if choice == choices[0] else "secondary", 48.0, "event_choice_%d" % choices.find(choice))
			choice_button.add_to_group("critical_cta")
			event_box.add_child(choice_button)
		event_box.add_child(_label("%s 미응답 시 안전한 기본 선택이 적용됩니다." % _duration_label(_config_int("eventChoiceTimeoutSeconds", 86400)), 16, PixelTokens.INK_MUTED))
		event_card.add_child(event_box)
		body.add_child(event_card)


func _build_profile_sheet(body: VBoxContainer) -> void:
	var intro := _card("gold")
	var intro_box := VBoxContainer.new()
	intro_box.add_theme_constant_override("separation", 8)
	intro_box.add_child(_label("성인 왕립 아카데미 수련생", 20, PixelTokens.ACCENT))
	intro_box.add_child(_label("나이로 종료되지 않으며 선택한 전문 분야를 끝없이 개척합니다.", 16, PixelTokens.INK_MUTED))
	intro.add_child(intro_box)
	body.add_child(intro)

	if int(_read(["lifetimeStats", "activities"], 0)) > 0:
		var warning := _card("coral")
		warning.add_child(_label("새로 만들면 %s의 지금 기록은 지워져요. 이어서 하려면 닫기를 누르세요." % str(_state.get("traineeName", "수련생")), 16, PixelTokens.NEGATIVE))
		body.add_child(warning)
	body.add_child(_label("수련생 이름", 17, PixelTokens.INK))
	_trainee_name_edit = LineEdit.new()
	_trainee_name_edit.custom_minimum_size.y = 48.0
	_trainee_name_edit.placeholder_text = "이름을 입력하세요"
	_trainee_name_edit.text = str(_state.get("traineeName", "아리아"))
	_trainee_name_edit.max_length = 16
	body.add_child(_trainee_name_edit)
	body.add_child(_label("첫 방향은 생성 후 계획 탭에서 언제든 바꿀 수 있습니다.", 16, PixelTokens.INK_MUTED))

	var preset_grid := GridContainer.new()
	preset_grid.columns = 2
	preset_grid.add_theme_constant_override("h_separation", PixelTokens.GRID_GAP)
	preset_grid.add_theme_constant_override("v_separation", 8)
	for preset in PRESETS:
		# 새 수련생은 1단계부터 시작하므로 직접 설계는 보이지 않는다.
		if str(preset["id"]) == "custom":
			continue
		var create_button := _button("%s\n%s" % [preset["name"], preset["hint"]], _create_trainee.bind(str(preset["id"])), "secondary", 60.0, "create_%s" % preset["id"])
		create_button.icon = _icon_texture(_preset_icon(str(preset["id"])))
		create_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		preset_grid.add_child(create_button)
	body.add_child(preset_grid)


func _build_continue_sheet(body: VBoxContainer) -> void:
	var save_card := _card("gold")
	var save_box := VBoxContainer.new()
	save_box.add_theme_constant_override("separation", 8)
	save_box.add_child(_label(str(_state.get("traineeName", "수련생")), 24, PixelTokens.ACCENT))
	save_box.add_child(_label("%d연차 %d시즌 · 세계 티어 %d" % [int(_read(["time", "year"], 1)), int(_read(["time", "season"], 1)), int(_state.get("worldTier", 1))], 16, PixelTokens.INK))
	save_box.add_child(_label("현재 활동 · %s" % _current_activity_name(), 16, PixelTokens.INK_MUTED))
	save_card.add_child(save_box)
	body.add_child(save_card)
	var continue_button := _button("이 기록으로 이어하기", _continue_game, "primary", 48.0, "continue_game")
	continue_button.add_to_group("critical_cta")
	body.add_child(continue_button)
	body.add_child(_button("새 수련생 만들기", _replace_sheet.bind("profile"), "secondary"))


func _build_reset_sheet(body: VBoxContainer) -> void:
	var warning := _card("coral")
	var warning_box := VBoxContainer.new()
	warning_box.add_theme_constant_override("separation", 8)
	warning_box.add_child(_label("되돌릴 수 없는 작업입니다.", 21, PixelTokens.NEGATIVE))
	warning_box.add_child(_label("현재 능력치·장비·계약·칭호·이벤트 기록이 모두 초기화됩니다.", 16, PixelTokens.INK))
	warning.add_child(warning_box)
	body.add_child(warning)
	body.add_child(_button("초기화하지 않고 돌아가기", _replace_sheet.bind("settings"), "primary"))
	body.add_child(_button("모든 데이터 초기화", _reset_game, "danger"))


func _replace_sheet(kind: String) -> void:
	_open_sheet(kind)


func _show_status_detail() -> void:
	_show_toast("%s\n이유 · %s" % [_activity_label.text if _activity_label != null else _current_activity_name(), _planner_reason()])


func _toggle_auto() -> void:
	_auto_running = not _auto_running
	_state["settings"]["autoRun"] = _auto_running
	_activity_elapsed = 0.0
	if _engine != null:
		if _auto_running and _engine.has_method("resume"):
			_engine.call("resume")
		elif not _auto_running and _engine.has_method("pause"):
			_engine.call("pause")
		elif _engine.has_method("set_auto_run"):
			_engine.call("set_auto_run", _auto_running)
	_refresh_chrome()
	_persist_silently()
	_show_toast("자동 진행을 %s했어요." % ("시작" if _auto_running else "일시정지"))


func _complete_current_activity() -> void:
	var task = _read(["activeTask"], {})
	var remaining := 1
	if typeof(task) == TYPE_DICTIONARY:
		remaining = maxi(1, int(task.get("remainingSlots", task.get("durationSlots", 1))))
	_advance_slots(remaining, true)


func _advance_slots(count: int, show_feedback: bool = true) -> void:
	var feedback_checkpoint := _result_feedback_checkpoint()
	var result = null
	if _engine != null and _engine.has_method("advance_slots"):
		result = _engine.call("advance_slots", count, _now_unix())
		_adopt_engine_result(result)
		_persist_silently()
	else:
		for index in range(max(0, count)):
			_simulate_fallback_slot()
	_activity_elapsed = 0.0
	# 이번 진행으로 열린 단계는 결과 창이 뜨면 그 창에서, 아니면 알림 띠로 알린다.
	var unlock_notice := _take_unlock_notice()
	_refresh_chrome()
	# 손가락으로 목록을 끄는 중이면 자동 진행의 화면 갱신을 손을 뗄 때까지 미룬다.
	if not show_feedback and _list_in_motion():
		_page_dirty = true
	else:
		_render_current_page()
	_present_result_feedback(result, feedback_checkpoint, not show_feedback, unlock_notice)
	_track_event(&"slots_advanced", {"count": maxi(0, count), "manual": show_feedback})
	if show_feedback:
		_play_sfx(SynthAudioPort.CUE_REWARD)
		_show_toast("%s · 결과를 반영했어요." % str(_read(["lastResult", "title"], "%s 완료" % _current_activity_name())))


func _simulate_fallback_slot() -> void:
	var stats: Dictionary = _state["stats"]
	var meters: Dictionary = _state["meters"]
	var policy_preset := _policy_preset()
	var target := "intelligence"
	match policy_preset:
		"martial": target = "combat"
		"artist": target = "art"
		"leader": target = "communication"
		"care": target = "nursing"
		"explorer": target = "stamina"
		"prosperity": target = "refinement"
		"balanced": target = "discipline"
	stats[target] = float(stats.get(target, 0.0)) + 4.0
	meters["energy"] = clampf(float(meters.get("energy", 100.0)) - 7.0, 0.0, 100.0)
	meters["stress"] = clampf(float(meters.get("stress", 0.0)) + 3.0, 0.0, 100.0)
	if float(meters["energy"]) < 20.0 or float(meters["stress"]) >= float(_read(["growthPolicy", "maxStress"], 72.0)):
		_state["activeTask"] = {"id": "REST_HOME", "name": "기숙사 휴식", "reason": "회복 안전 규칙이 우선 적용되었어요."}
		meters["energy"] = minf(100.0, float(meters["energy"]) + 32.0)
		meters["stress"] = maxf(0.0, float(meters["stress"]) - 22.0)
	else:
		_state["activeTask"] = _fallback_activity_for_preset(policy_preset)
	var time_state: Dictionary = _state["time"]
	time_state["slot"] = int(time_state.get("slot", 0)) + 1
	var slots_per_season := maxi(1, _config_int("slotsPerSeason", 28))
	var seasons_per_year := maxi(1, _config_int("seasonsPerYear", 4))
	if int(time_state["slot"]) >= slots_per_season:
		time_state["slot"] = 0
		time_state["season"] = int(time_state.get("season", 1)) + 1
		if int(time_state["season"]) > seasons_per_year:
			time_state["season"] = 1
			time_state["year"] = int(time_state.get("year", 1)) + 1
	_state["lastResult"] = {"title": "%s 완료" % _current_activity_name(), "summary": "%s +4.0 · 숙련 +1" % str(STAT_LABELS.get(target, target))}


func _fallback_activity_for_preset(preset: String) -> Dictionary:
	match preset:
		"martial": return {"id": "EDU_FENCING", "name": "왕립 검술", "reason": "무예 방향의 전투·절제 성장을 우선했어요."}
		"artist": return {"id": "EDU_PAINTING", "name": "빛의 회화", "reason": "예술 방향과 최근 활동 다양성을 함께 고려했어요."}
		"leader": return {"id": "JOB_DIPLOMACY", "name": "외교 행사", "reason": "리더십과 주간 계약을 함께 진전시켜요."}
		"care": return {"id": "EDU_NURSING", "name": "왕립 간호학", "reason": "돌봄 방향의 핵심 숙련을 강화해요."}
		"explorer": return {"id": "ADV_FOREST", "name": "별빛 숲 원정", "reason": "탐험 방향과 현재 위험 허용도에 맞아요."}
		"prosperity": return {"id": "JOB_BANQUET", "name": "연회 운영", "reason": "최소 보유금을 지키며 골드 효율을 높여요."}
		"balanced": return {"id": "REST_WALK", "name": "왕도 산책", "reason": "최근 성장 벡터의 균형을 보완해요."}
		_: return {"id": "EDU_LITERATURE", "name": "왕립 교양학", "reason": "학문 방향과 계약 목표에 가장 잘 맞아요."}


# shown_conflicts: 원정 버튼이 화면에 알린 빠지는 시험 id. 누르는 순간 다시 계산해 다르면(열어 둔 사이 자동 진행이 지남)
# 출발하지 않고 화면을 새로 그려 다시 보여 준다. 안내 없이 시험에 빠지지 않게 한다. null이면 확인하지 않는다.
func _run_activity(activity_id: String, shown_conflicts: Variant = null) -> void:
	if _expedition_conflicts_changed(activity_id, shown_conflicts):
		_render_current_page()
		if _find_open_sheet("world"):
			_open_sheet("world")
		_show_toast(EXPEDITION_SCHEDULE_CHANGED)
		return
	var feedback_checkpoint := _result_feedback_checkpoint()
	var result = null
	if _engine != null and _engine.has_method("run_activity"):
		result = _engine.call("run_activity", activity_id, _now_unix())
	elif _engine != null and _engine.has_method("execute_activity"):
		result = _engine.call("execute_activity", activity_id, _now_unix())
	else:
		var definition := _activity_by_id(activity_id)
		if not definition.is_empty():
			_state["activeTask"] = {
				"id": activity_id,
				"name": str(definition.get("name", activity_id)),
				"reason": "플레이어가 즉시 활동으로 선택했어요.",
			}
		_advance_slots(1, true)
		return
	var succeeded := _result_ok(result)
	_adopt_engine_result(result)
	_persist_silently()
	# 실행으로 열린 단계는 결과 창에서 알린다(실패하면 결과 창이 없으므로 아래 알림 띠로).
	var unlock_notice := _take_unlock_notice() if succeeded else ""
	_refresh_chrome()
	_render_current_page()
	_track_event(&"activity_run", {"activityId": activity_id, "ok": succeeded})
	_play_sfx(SynthAudioPort.CUE_REWARD if succeeded else SynthAudioPort.CUE_FAILURE)
	if succeeded:
		_present_result_feedback(result, feedback_checkpoint, false, unlock_notice)
		var skipped_names: Array[String] = []
		for raw_skipped: Variant in (result as Dictionary).get("skippedChallenges", []) as Array:
			skipped_names.append(_activity_name_by_id(str(raw_skipped)))
		if skipped_names.is_empty():
			_show_toast("%s 1회를 해결했어요." % _activity_name_by_id(activity_id))
		else:
			_show_toast("%s 1회를 해결했어요.\n%s에는 불참했어요." % [_activity_name_by_id(activity_id), ", ".join(skipped_names)])
	else:
		_show_toast(_friendly_rejection(str((result as Dictionary).get("error", "활동을 실행하지 못했어요.")), activity_id) if result is Dictionary else "활동을 실행하지 못했어요.")


func _queue_activity(activity_id: String) -> void:
	var queued := false
	if _engine != null and _engine.has_method("queue_activity"):
		var result = _engine.call("queue_activity", activity_id)
		queued = result is Dictionary and bool((result as Dictionary).get("ok", false))
		_sync_engine_state()
	else:
		var queue: Array = _state.get("activityQueue", []) as Array
		queue.append(activity_id)
		queued = true
	if queued:
		_persist_silently()
		_render_current_page()
		_show_toast("%s 자동 큐에 넣었어요." % _josa(_activity_name_by_id(activity_id), "을", "를"))
	else:
		_show_toast("현재 조건에서는 자동 큐에 추가할 수 없어요.")


func _remove_queued_activity(queue_index: int) -> void:
	var updated := false
	if _engine != null and _engine.has_method("remove_queued_activity"):
		updated = _result_ok(_engine.call("remove_queued_activity", queue_index))
		_sync_engine_state()
	else:
		var queue: Array = _state.get("activityQueue", []) as Array
		if queue_index >= 0 and queue_index < queue.size():
			queue.remove_at(queue_index)
			updated = true
	_finish_queue_edit(updated, "자동 큐에서 활동을 제거했습니다.")


func _move_queued_activity(queue_index: int, offset: int) -> void:
	var updated := false
	if _engine != null and _engine.has_method("move_queued_activity"):
		updated = _result_ok(_engine.call("move_queued_activity", queue_index, offset))
		_sync_engine_state()
	else:
		var queue: Array = _state.get("activityQueue", []) as Array
		if queue_index >= 0 and queue_index < queue.size():
			var destination := clampi(queue_index + offset, 0, queue.size() - 1)
			if destination == queue_index:
				_finish_queue_edit(false, "")
				return
			var value = queue.pop_at(queue_index)
			queue.insert(destination, value)
			updated = true
	_finish_queue_edit(updated, "자동 큐 순서를 바꿨습니다.")


func _clear_activity_queue() -> void:
	var updated := false
	if _engine != null and _engine.has_method("clear_activity_queue"):
		updated = _result_ok(_engine.call("clear_activity_queue"))
		_sync_engine_state()
	else:
		(_state.get("activityQueue", []) as Array).clear()
		updated = true
	_finish_queue_edit(updated, "자동 큐를 비웠습니다.")


func _finish_queue_edit(updated: bool, success_message: String) -> void:
	if updated:
		_persist_silently()
		_render_current_page()
		_show_toast(success_message)
	else:
		_show_toast("자동 큐를 변경하지 못했어요.")


func _pin_contract(contract_id: String) -> void:
	var updated := false
	if _engine != null and _engine.has_method("pin_contract"):
		updated = bool(_engine.call("pin_contract", contract_id))
		_sync_engine_state()
	else:
		var generated: Dictionary = _state.get("generatedContent", {}) as Dictionary
		generated["pinnedContractId"] = contract_id
		updated = true
	if updated:
		_persist_silently()
		_render_current_page()
		_show_toast("계약 고정을 해제했어요." if contract_id.is_empty() else "계약을 자동 플래너 우선 목표로 고정했어요.")
	else:
		_show_toast("계약 고정을 변경하지 못했어요.")


func _run_world_activity(activity_id: String, shown_conflicts: Variant = null) -> void:
	_run_activity(activity_id, shown_conflicts)
	if _modal_layer != null and _modal_layer.get_child_count() > 1:
		_open_sheet("world")


func _apply_preset(preset: String) -> void:
	var policy: Dictionary = _read(["growthPolicy"], {}).duplicate(true)
	policy["preset"] = preset
	if preset != "custom":
		policy["weights"] = {}
	_apply_policy(policy)
	_render_current_page()
	_show_toast("성장 방향을 %s으로 변경했어요." % _preset_name(preset))


func _toggle_banned_tag(tag_id: String) -> void:
	var policy: Dictionary = _read(["growthPolicy"], {}).duplicate(true)
	var banned: Array = policy.get("bannedTags", []).duplicate()
	if banned.has(tag_id):
		banned.erase(tag_id)
	else:
		banned.append(tag_id)
	policy["bannedTags"] = banned
	_apply_policy(policy)
	_render_current_page()


func _on_policy_slider_changed(value: float, key: String, value_label: Label, formatter: Callable) -> void:
	var policy: Dictionary = _read(["growthPolicy"], {}).duplicate(true)
	if key.begins_with("weight:"):
		var weights: Dictionary = policy.get("weights", {}).duplicate(true)
		var weight_key := key.trim_prefix("weight:")
		weights = _rebalance_custom_weights(weights, weight_key, value / 100.0)
		policy["preset"] = "custom"
		policy["weights"] = weights
	elif key == "reserveGoldValue":
		policy["reserveGold"] = _number_to_big(value)
	else:
		policy[key] = value
	_apply_policy(policy)
	if key.begins_with("weight:"):
		var normalized_value := float(_read(["growthPolicy", "weights", key.trim_prefix("weight:")], 0.0)) * 100.0
		value_label.text = str(formatter.call(normalized_value))
		_sync_custom_weight_sliders()
	else:
		value_label.text = str(formatter.call(value))


func _rebalance_custom_weights(current_weights: Dictionary, selected_key: String, selected_ratio: float) -> Dictionary:
	var result: Dictionary = {}
	var keys := _custom_weight_keys()
	var selected := clampf(selected_ratio, 0.0, 1.0)
	var other_total := 0.0
	for weight_key: String in keys:
		if weight_key != selected_key:
			other_total += maxf(0.0, float(current_weights.get(weight_key, 0.0)))
	var remaining := 1.0 - selected
	var fallback_share := remaining / float(maxi(1, keys.size() - 1))
	for weight_key: String in keys:
		if weight_key == selected_key:
			result[weight_key] = selected
		elif other_total > 0.0:
			result[weight_key] = maxf(0.0, float(current_weights.get(weight_key, 0.0))) / other_total * remaining
		else:
			result[weight_key] = fallback_share
	return result


func _custom_weight_keys() -> Array[String]:
	var result: Array[String] = []
	for raw_key: Variant in STAT_LABELS.keys():
		result.append(str(raw_key))
	result.append("reputation")
	result.append("gold")
	return result


func _sync_custom_weight_sliders() -> void:
	if _content_host == null or not is_inside_tree():
		return
	var weights: Dictionary = _read(["growthPolicy", "weights"], {})
	for raw_node: Node in get_tree().get_nodes_in_group("policy_stepper"):
		if not is_ancestor_of(raw_node):
			continue
		var policy_key := str(raw_node.get_meta("policy_key", ""))
		if not policy_key.begins_with("weight:"):
			continue
		var displayed_value := float(weights.get(policy_key.trim_prefix("weight:"), 0.0)) * 100.0
		raw_node.set_meta("policy_value", displayed_value)
		var label_value: Variant = raw_node.get_meta("policy_value_label", null)
		if label_value is Label and is_instance_valid(label_value):
			(label_value as Label).text = "%d%%" % int(round(displayed_value))
		_update_stepper_buttons(raw_node as Control, displayed_value, 0.0, 100.0)


func _apply_policy(policy: Dictionary) -> void:
	_state["growthPolicy"] = policy
	if _engine != null and _engine.has_method("set_policy"):
		var result = _engine.call("set_policy", policy)
		_adopt_engine_result(result)
		_persist_silently()
	_refresh_chrome()


func _select_activity_filter(kind: String) -> void:
	_activity_filter = kind
	_render_current_page()


func _toggle_setting(pressed: bool, key: String) -> void:
	if not _state.has("settings") or typeof(_state["settings"]) != TYPE_DICTIONARY:
		_state["settings"] = {}
	_state["settings"][key] = pressed
	if key == "autoRun":
		_auto_running = pressed
		_activity_elapsed = 0.0
	elif key == "sound" and _audio_port != null and _audio_port.has_method("set_enabled"):
		_audio_port.call("set_enabled", pressed)
	elif key == "reducedMotion":
		if _result_feedback_layer != null and _result_feedback_layer.has_method("set_reduced_motion"):
			_result_feedback_layer.call("set_reduced_motion", pressed)
		if _home_avatar != null and is_instance_valid(_home_avatar) and _home_avatar.has_method("set_reduced_motion"):
			_home_avatar.call("set_reduced_motion", pressed)
	if _engine != null:
		if _engine.has_method("set_setting"):
			_engine.call("set_setting", key, pressed)
		elif _engine.has_method("set_settings"):
			_engine.call("set_settings", _state["settings"])
	_refresh_chrome()
	if key == "highContrast":
		_refresh_high_contrast()
	_persist_silently()
	_track_event(&"setting_changed", {"setting": key, "enabled": pressed})
	_show_toast("설정을 반영했어요.")


func _collect_offline() -> void:
	var pending := clampi(int(_state.get("pendingOfflineSlots", 0)), 0, _offline_cap_slots())
	var before := _progress_snapshot()
	var offline_summary: Dictionary = {}
	if _engine != null and _engine.has_method("settle_offline"):
		var result = _engine.call("settle_offline", _now_unix())
		if result is Dictionary:
			offline_summary = (result as Dictionary).duplicate(true)
		_adopt_engine_result(result)
	elif pending > 0:
		_advance_slots(pending, false)
	_state["pendingOfflineSlots"] = 0
	offline_summary["changes"] = _progress_changes(before, _progress_snapshot())
	offline_summary["unlockLabels"] = _absorb_offline_unlocks(offline_summary)
	# 정산 알림에는 직전 온라인 새로 열림 문구를 붙이지 않는다(새로 열린 단계가 없을 때도).
	_unlock_notice_until = 0
	_state["lastOfflineSummary"] = offline_summary
	_persist_silently()
	_refresh_chrome()
	# 시트 아래의 홈도 정산 뒤 값으로 다시 그린다.
	_render_current_page()
	_open_sheet("offline")
	_track_event(&"offline_settled", {"requestedSlots": pending, "settledSlots": int(offline_summary.get("slotsAdvanced", pending))})
	_play_sfx(SynthAudioPort.CUE_REWARD if pending > 0 else SynthAudioPort.CUE_FAILURE)
	_show_toast("오프라인 결과를 반영했어요.")


# 오프라인 정산 전후로 무엇이 바뀌었는지 보여 주기 위한 요약 값
func _progress_snapshot() -> Dictionary:
	var stat_total := 0.0
	for value in (_read(["stats"], {}) as Dictionary).values():
		stat_total += float(value)
	# 같은 이벤트가 여러 번 처리되면 기록 항목의 count만 늘어나므로 count를 합산한다.
	var events_handled := 0
	for entry in (_read(["eventHistory"], {}) as Dictionary).values():
		events_handled += int((entry as Dictionary).get("count", 1)) if entry is Dictionary else 1
	return {
		"worldTier": int(_state.get("worldTier", 1)),
		"titles": _career_title_count(),
		"stats": stat_total,
		"gold": _big_to_number(_read(["bigValues", "gold"], {"mantissa": 0, "exponent": 0})),
		"events": events_handled,
	}


func _progress_changes(before: Dictionary, after: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if int(after["worldTier"]) != int(before["worldTier"]):
		lines.append("세계 티어 %d > %d" % [int(before["worldTier"]), int(after["worldTier"])])
	if int(after["titles"]) > int(before["titles"]):
		lines.append("새 진로 칭호 %d개" % (int(after["titles"]) - int(before["titles"])))
	if float(after["stats"]) - float(before["stats"]) >= 1.0:
		lines.append("능력치 합 +%s" % _format_number(float(after["stats"]) - float(before["stats"])))
	var gold_delta := float(after["gold"]) - float(before["gold"])
	if absf(gold_delta) >= 1.0:
		lines.append("골드 %s%s" % ["+" if gold_delta > 0.0 else "-", _format_number(absf(gold_delta))])
	if int(after["events"]) > int(before["events"]):
		lines.append("처리한 이벤트 %d건" % (int(after["events"]) - int(before["events"])))
	return lines


func _resolve_event(event_id: String, choice_id: String) -> void:
	var succeeded := false
	if _engine != null and _engine.has_method("resolve_event"):
		var result = _engine.call("resolve_event", event_id, choice_id)
		succeeded = _result_ok(result)
		_adopt_engine_result(result)
	else:
		var events := _event_inbox()
		for index in range(events.size() - 1, -1, -1):
			if typeof(events[index]) == TYPE_DICTIONARY and str(events[index].get("id", "")) == event_id:
				events.remove_at(index)
				succeeded = true
				break
		_state["eventInbox"] = events
	_persist_silently()
	_open_sheet("event")
	_track_event(&"event_resolved", {"eventId": event_id, "choiceId": choice_id, "ok": succeeded})
	_play_sfx(SynthAudioPort.CUE_REWARD if succeeded else SynthAudioPort.CUE_FAILURE)
	_show_toast("선택을 기록했어요. 자동 성장은 계속돼요." if succeeded else "이벤트 선택을 반영하지 못했어요.")


func _shop_action(item_id: String) -> void:
	var completed := false
	var error_message := "구매 조건을 확인해 주세요."
	if _engine != null and _engine.has_method("buy_item"):
		var result = _engine.call("buy_item", item_id)
		completed = _result_ok(result)
		if result is Dictionary:
			error_message = str((result as Dictionary).get("error", error_message))
		_sync_engine_state()
	elif _engine != null and _engine.has_method("purchase_item"):
		var result = _engine.call("purchase_item", item_id)
		completed = _result_ok(result)
		if result is Dictionary:
			error_message = str((result as Dictionary).get("error", error_message))
		_sync_engine_state()
	_track_event(&"shop_action", {"itemId": item_id, "ok": completed})
	_play_sfx(SynthAudioPort.CUE_REWARD if completed else SynthAudioPort.CUE_FAILURE)
	if completed:
		_show_toast("%s 인벤토리에 넣었어요." % _josa(_item_display_name(item_id), "을", "를"))
	else:
		_show_toast(error_message)
	_persist_silently()
	_render_current_page()
	_open_sheet("shop")


func _open_shop_for_gift(relation_id: String) -> void:
	_gift_target = relation_id if RELATION_LABELS.has(relation_id) else "citizens"
	_open_sheet("shop")


func _select_gift_target(relation_id: String) -> void:
	if RELATION_LABELS.has(relation_id):
		_gift_target = relation_id
		_open_sheet("shop")


func _gift_item(item_id: String, relation_id: String) -> void:
	var result: Variant = {"ok": false, "error": "선물 기능을 사용할 수 없습니다."}
	if _engine != null and _engine.has_method("gift_item"):
		result = _engine.call("gift_item", item_id, relation_id)
		_sync_engine_state()
	var succeeded := _result_ok(result)
	if succeeded:
		_persist_silently()
		_render_current_page()
	_track_event(&"gift_item", {"itemId": item_id, "relation": relation_id, "ok": succeeded})
	_play_sfx(SynthAudioPort.CUE_REWARD if succeeded else SynthAudioPort.CUE_FAILURE)
	_show_toast(
		"%s에게 %s 선물했어요." % [str(RELATION_LABELS.get(relation_id, relation_id)), _josa(_item_display_name(item_id), "을", "를")]
		if succeeded else str((result as Dictionary).get("error", "선물을 건네지 못했습니다."))
	)
	_open_sheet("shop")


func _inventory_action(action: String, item_id: String) -> void:
	var result: Variant = {"ok": false, "error": "지원하지 않는 인벤토리 작업"}
	if _engine != null:
		match action:
			"equip":
				if _engine.has_method("equip_item"):
					result = _engine.call("equip_item", item_id)
			"unequip":
				var slot := _equipped_slot_for(item_id)
				if _engine.has_method("unequip") and not slot.is_empty():
					result = {"ok": bool(_engine.call("unequip", slot))}
			"use":
				if _engine.has_method("use_item"):
					result = _engine.call("use_item", item_id)
			"sell":
				if _engine.has_method("sell_item"):
					result = _engine.call("sell_item", item_id, 1)
	_sync_engine_state()
	var succeeded := _result_ok(result)
	_persist_silently()
	_track_event(&"inventory_action", {"action": action, "itemId": item_id, "ok": succeeded})
	_play_sfx(SynthAudioPort.CUE_REWARD if succeeded else SynthAudioPort.CUE_FAILURE)
	_show_toast(
		"%s · %s" % [_item_display_name(item_id), {"equip": "장착", "unequip": "해제", "use": "사용", "sell": "판매"}.get(action, action)]
		if succeeded else str((result as Dictionary).get("error", "인벤토리 작업을 반영하지 못했습니다."))
	)
	_render_current_page()
	_open_sheet("shop")


func _save_game() -> void:
	var called := _persist_silently()
	_show_toast("현재 수련 기록을 저장했어요." if called else "현재 세션 상태를 유지했어요.")


func _continue_game() -> void:
	if _engine != null:
		for method in ["load_game", "load_save", "load"]:
			if _engine.has_method(method):
				_engine.call(method)
				break
		_sync_engine_state()
	_state["pendingOfflineSlots"] = _pending_offline_slots()
	_auto_running = bool(_read(["settings", "autoRun"], true))
	_close_sheet()
	_show_tab("home")
	_refresh_chrome()
	if int(_state.get("pendingOfflineSlots", 0)) > 0:
		_open_sheet("offline")
	_show_toast("최신 수련 기록으로 이어가요.")


func _create_trainee(preset: String) -> void:
	var trainee_name := "새 수련생"
	if _trainee_name_edit != null and not _trainee_name_edit.text.strip_edges().is_empty():
		trainee_name = _trainee_name_edit.text.strip_edges()
	_seed += 1
	if _engine != null and _engine.has_method("initialize"):
		_engine.call("initialize", _seed)
		if _engine.has_method("set_trainee_name"):
			_engine.call("set_trainee_name", trainee_name)
		elif _engine.has_method("set_player_name"):
			_engine.call("set_player_name", trainee_name)
		_sync_engine_state()
		_stamp_engine_time_boundary()
	else:
		_state = _fallback_state()
	_state["traineeName"] = trainee_name
	_auto_running = true
	var policy: Dictionary = _read(["growthPolicy"], {}).duplicate(true)
	policy["preset"] = preset
	if preset != "custom":
		policy["weights"] = {}
	_apply_policy(policy)
	_close_sheet()
	_show_tab("home")
	_refresh_chrome()
	_show_toast("%s의 수련을 시작해요." % trainee_name)


func _reset_game() -> void:
	if _engine != null:
		if _engine.has_method("reset_save"):
			_engine.call("reset_save")
		elif _engine.has_method("delete_save"):
			_engine.call("delete_save")
		if _engine.has_method("initialize"):
			_engine.call("initialize", _seed)
		_sync_engine_state()
		_stamp_engine_time_boundary()
	else:
		_state = _fallback_state()
	_auto_running = true
	_persist_silently()
	_close_sheet()
	_show_tab("home")
	_refresh_chrome()
	_show_toast("새 수련 기록을 시작했어요.")


func _refresh_chrome() -> void:
	_announce_unlocks()
	_refresh_navigation()
	if _header_gold_label != null:
		_header_gold_label.text = "%s G" % _format_big(_read(["bigValues", "gold"], {"mantissa": 0, "exponent": 0}))
	if _header_time_label != null:
		_header_time_label.text = "%d연차 · %d시즌" % [int(_read(["time", "year"], 1)), int(_read(["time", "season"], 1))]
	if _header_name_label != null:
		_header_name_label.text = str(_state.get("traineeName", "수련생"))
	if _header_tier_label != null:
		_header_tier_label.text = "세계 티어 %d" % int(_state.get("worldTier", 1))
	if _activity_label != null:
		_activity_label.text = ("지금, %s" if _auto_running else "일시정지 · %s") % _current_activity_name()
	if _reason_label != null:
		_reason_label.text = _planner_reason()
	if _pause_button != null:
		_pause_button.icon = _icon_texture("pause" if _auto_running else "play")
		_pause_button.tooltip_text = "일시정지" if _auto_running else "계속하기"
		_pause_button.theme_type_variation = PixelTheme.button_variation("gold" if _auto_running else "primary")


func _refresh_high_contrast() -> void:
	theme = PixelTheme.build(bool(_read(["settings", "highContrast"], false)))


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "Toast"
	_toast_panel.anchor_left = 0.04
	_toast_panel.anchor_right = 0.96
	_toast_panel.anchor_top = 1.0
	_toast_panel.anchor_bottom = 1.0
	_toast_panel.offset_top = -150.0
	_toast_panel.offset_bottom = -94.0
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 여러 줄 알림은 아래 탭을 가리지 않도록 위로 늘어난다.
	_toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_panel.z_index = 100
	_toast_panel.theme_type_variation = PixelTheme.panel_variation("toast")
	_toast_label = _label("", 16, PixelTokens.ON_STRIP, HORIZONTAL_ALIGNMENT_CENTER)
	PixelText.wrap_at_spaces(_toast_label)
	_toast_panel.add_child(_toast_label)
	_toast_panel.visible = false
	_modal_layer.add_child(_toast_panel)


func _show_toast(message: String) -> void:
	if _toast_panel == null:
		return
	_toast_serial += 1
	var serial := _toast_serial
	# 방금 띄운 새로 열림 알림은 다른 알림에 덮이지 않고 함께 보인다.
	if message != _unlock_notice_text and Time.get_ticks_msec() < _unlock_notice_until:
		message = "%s\n%s" % [_unlock_notice_text, message]
	PixelText.set_text(_toast_label, message)
	_toast_panel.visible = true
	_toast_panel.modulate = Color.WHITE
	get_tree().create_timer(2.2).timeout.connect(func():
		if serial == _toast_serial and is_instance_valid(_toast_panel):
			_toast_panel.visible = false
	)


func _result_feedback_checkpoint() -> Dictionary:
	var history: Array = _state.get("seasonHistory", []) as Array
	return {
		"lastResult": (_state.get("lastResult", {}) as Dictionary).duplicate(true),
		"seasonHistorySize": history.size(),
	}


# automatic: 자동 진행으로 끝난 결과. 평범한 활동 결과는 작은 띠로만 알리고, 도전·모험·심사·칭호·업무 사고는 결과 창으로 보여 준다.
# unlock_notice: 같은 진행으로 열린 단계. 결과 창이 뜨면 그 창의 첫 줄로 보이고, 띠나 결과가 없으면 알림 띠로 알린다.
func _present_result_feedback(engine_result: Variant, checkpoint: Dictionary, automatic: bool = false, unlock_notice: String = "") -> void:
	if _result_feedback_layer == null or not _result_feedback_layer.has_method("present"):
		_show_unlock_notice(unlock_notice)
		return
	var completed: Array[Dictionary] = []
	var reviews: Array[Dictionary] = []
	if engine_result is Dictionary:
		var result_dict := engine_result as Dictionary
		for raw_completed: Variant in result_dict.get("completedActivities", []) as Array:
			if raw_completed is Dictionary:
				completed.append((raw_completed as Dictionary).duplicate(true))
		if result_dict.get("result") is Dictionary:
			completed.append((result_dict.get("result") as Dictionary).duplicate(true))
		for raw_review: Variant in result_dict.get("seasonReviews", []) as Array:
			if raw_review is Dictionary:
				reviews.append((raw_review as Dictionary).duplicate(true))

	var history: Array = _state.get("seasonHistory", []) as Array
	var previous_history_size := clampi(int(checkpoint.get("seasonHistorySize", history.size())), 0, history.size())
	if reviews.is_empty() and history.size() > previous_history_size:
		for index: int in range(previous_history_size, history.size()):
			if history[index] is Dictionary:
				reviews.append((history[index] as Dictionary).duplicate(true))

	if completed.is_empty():
		var current_last: Dictionary = _state.get("lastResult", {}) as Dictionary
		var previous_last: Dictionary = checkpoint.get("lastResult", {}) as Dictionary
		if not current_last.is_empty() and JSON.stringify(current_last, "", true, true) != JSON.stringify(previous_last, "", true, true):
			completed.append(current_last.duplicate(true))

	var activity_result: Dictionary = completed.back() if not completed.is_empty() else {}
	var season_review: Dictionary = reviews.back() if not reviews.is_empty() else {}
	var payload := _build_result_feedback_payload(activity_result, season_review)
	if payload.is_empty():
		_show_unlock_notice(unlock_notice)
		return
	# 평범한 근무("근무 결과 · 평온한 근무")도 띠로 알리고, 업무 사고가 있을 때만 결과 창을 띄운다.
	var incident := bool((activity_result.get("outcome", {}) as Dictionary).get("incident", false))
	# 새 단계가 열린 순간의 결과는 자동 진행이어도 결과 창으로 보여 그 첫 줄에서 알린다(한 줄 띠와 알림 띠가 겹치지 않게).
	var routine := automatic and str(payload.get("kind", "")) == "activity" and not incident and unlock_notice.is_empty()
	if not unlock_notice.is_empty():
		payload["notice"] = unlock_notice
	_raise_feedback_layer()
	_result_feedback_layer.call("present", payload, bool(_read(["settings", "reducedMotion"], false)), routine)


func _build_result_feedback_payload(activity_result: Dictionary, season_review: Dictionary = {}) -> Dictionary:
	if not season_review.is_empty():
		return _build_review_feedback_payload(season_review, activity_result)
	if activity_result.is_empty():
		return {}
	if str(activity_result.get("kind", "")) == "challenge":
		return _build_challenge_feedback_payload(activity_result)
	if str(activity_result.get("kind", "")) == "adventure":
		return _build_adventure_feedback_payload(activity_result)
	return _build_activity_feedback_payload(activity_result)


func _build_activity_feedback_payload(activity_result: Dictionary) -> Dictionary:
	var details: Array[String] = []
	details.append_array(_result_specialized_summary_lines(activity_result))
	var growth_line := _feedback_growth_line(activity_result.get("gains", {}) as Dictionary)
	if not growth_line.is_empty():
		details.append(growth_line)
	details.append_array(_feedback_reward_lines(activity_result))
	var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
	var relation_gain := float(outcome.get("relationGain", 0.0))
	var reputation_gain := float(outcome.get("reputationGain", 0.0))
	if relation_gain > 0.0 or reputation_gain > 0.0:
		var social_parts: Array[String] = []
		if reputation_gain > 0.0:
			social_parts.append("평판 +%s" % _feedback_number(reputation_gain))
		if relation_gain > 0.0:
			social_parts.append("관계 +%s" % _feedback_number(relation_gain))
		details.append("교류 · %s" % " · ".join(social_parts))
	if int(activity_result.get("mastery", 0)) > 0:
		details.append("숙련 · %d" % int(activity_result.get("mastery", 0)))
	if details.is_empty() and not str(activity_result.get("summary", "")).is_empty():
		details.append(str(activity_result.get("summary", "")))
	var had_incident := bool(outcome.get("incident", false))
	return {
		"kind": "activity",
		"badge": "사고" if had_incident else "성장",
		"tone": "coral" if had_incident else "raised",
		"headline": str(activity_result.get("title", "활동 완료")),
		"floatingStats": _feedback_stat_tokens(activity_result.get("gains", {}) as Dictionary),
		"details": details,
	}


func _build_challenge_feedback_payload(activity_result: Dictionary) -> Dictionary:
	var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
	if outcome.is_empty():
		return _build_activity_feedback_payload(activity_result)
	var won := bool(outcome.get("won", false))
	var details: Array[String] = []
	if outcome.has("playerScore") and outcome.has("opponentScore"):
		details.append("점수 · 나 %.1f / %s %.1f" % [
			float(outcome.get("playerScore", 0.0)),
			str(outcome.get("rivalName", "상대")),
			float(outcome.get("opponentScore", 0.0)),
		])
	var rank := str(outcome.get("rank", "")).strip_edges()
	var league_before := int(outcome.get("leagueTier", 0))
	var league_after := int(outcome.get("nextLeagueTier", league_before))
	var rank_parts: Array[String] = []
	if not rank.is_empty():
		rank_parts.append("등급 %s" % _challenge_rank_name(rank))
	if league_before > 0:
		rank_parts.append("리그 %d > %d" % [league_before, league_after])
	if not rank_parts.is_empty():
		details.append("판정 · %s" % " · ".join(rank_parts))
	var hint := str(outcome.get("hint", "")).strip_edges()
	if not won and not hint.is_empty():
		# 실패했을 때 가장 쓸모 있는 조언이 결과 창의 첫 줄(2줄 허용)에 오게 한다. 승리 때의 일반 문구는 보상·성장 줄에 자리를 내준다.
		details.insert(0, "다음 준비 · %s" % hint)
	var growth_line := _feedback_growth_line(activity_result.get("gains", {}) as Dictionary)
	if not growth_line.is_empty():
		details.append(growth_line)
	details.append_array(_feedback_reward_lines(activity_result))
	return {
		"kind": "challenge",
		"badge": "도전",
		"tone": "gold" if won else "coral",
		"headline": "%s · %s" % ["승리" if won else "도전 경험", _feedback_activity_name(activity_result)],
		"floatingStats": _feedback_stat_tokens(activity_result.get("gains", {}) as Dictionary),
		"details": details,
	}


func _build_adventure_feedback_payload(activity_result: Dictionary) -> Dictionary:
	var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
	if outcome.is_empty():
		return _build_activity_feedback_payload(activity_result)
	var won := bool(outcome.get("won", false))
	var details := _result_specialized_summary_lines(activity_result)
	var growth_line := _feedback_growth_line(activity_result.get("gains", {}) as Dictionary)
	if not growth_line.is_empty():
		details.append(growth_line)
	details.append_array(_feedback_reward_lines(activity_result))
	var region_name := str(outcome.get("regionName", _feedback_activity_name(activity_result)))
	return {
		"kind": "challenge",
		"badge": "원정",
		"tone": "gold" if won else "coral",
		"headline": "%s · %s" % ["원정 성공" if won else "원정 후퇴", region_name],
		"floatingStats": _feedback_stat_tokens(activity_result.get("gains", {}) as Dictionary),
		"details": details,
	}


func _result_specialized_summary_lines(activity_result: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
	if outcome.is_empty():
		return lines
	var kind := str(activity_result.get("kind", outcome.get("type", "")))
	if kind == "challenge":
		if outcome.has("playerScore") and outcome.has("opponentScore"):
			var rank := str(outcome.get("rank", "")).strip_edges()
			lines.append("도전 점수 · 나 %.1f / 상대 %.1f%s" % [
				float(outcome.get("playerScore", 0.0)),
				float(outcome.get("opponentScore", 0.0)),
					" · %s" % _challenge_rank_name(rank) if not rank.is_empty() else "",
			])
		var hint := str(outcome.get("hint", "")).strip_edges()
		if not hint.is_empty():
			lines.append("다음 준비 · %s" % hint)
		return lines
	if kind == "job":
		var incident_name := str(outcome.get("event", "근무 완료")).strip_edges()
		if bool(outcome.get("incident", false)):
			var incident_parts: Array[String] = []
			var effects: Dictionary = outcome.get("effects", {}) as Dictionary
			var stress_gain := float(effects.get("stress", 0.0))
			var citizen_delta := float(effects.get("citizens", 0.0))
			if stress_gain > 0.0:
				incident_parts.append("스트레스 +%s" % _feedback_number(stress_gain))
			if citizen_delta < 0.0:
				incident_parts.append("시민 관계 %s" % _feedback_number(citizen_delta))
			var reward_multiplier := float(outcome.get("rewardMultiplier", 1.0))
			if reward_multiplier < 1.0:
				incident_parts.append("보수 %d%%" % int(round(reward_multiplier * 100.0)))
			lines.append("돌발 사건 · %s%s" % [
				incident_name,
				" · %s" % " · ".join(incident_parts) if not incident_parts.is_empty() else "",
			])
		elif not incident_name.is_empty():
			lines.append("근무 결과 · %s" % incident_name)
		return lines
	if kind != "adventure":
		return lines

	var node_parts: Array[String] = []
	var node_labels := {"exploration": "탐색", "event": "사건", "encounter": "조우", "boss": "보스"}
	for raw_node: Variant in outcome.get("nodes", []) as Array:
		if raw_node is not Dictionary:
			continue
		var node := raw_node as Dictionary
		var node_type := str(node.get("type", "node"))
		var event_name := str(node.get("event", "")).strip_edges()
		var node_text := str(node_labels.get(node_type, node_type))
		var enemy_name := str(node.get("enemyName", "")).strip_edges()
		var enemy_trait := str(node.get("enemyTraitName", "")).strip_edges()
		if ["encounter", "boss"].has(node_type) and not enemy_name.is_empty():
			node_text += " %s%s" % [enemy_name, " (%s)" % enemy_trait if not enemy_trait.is_empty() else ""]
		elif not event_name.is_empty():
			node_text += " %s" % event_name
		node_parts.append(node_text)
	if not node_parts.is_empty():
		lines.append("3노드 · %s" % " > ".join(node_parts))

	var result_parts: Array[String] = []
	if bool(outcome.get("injured", false)):
		result_parts.append("부상")
		result_parts.append("다음 일정 강제 휴식")
	else:
		result_parts.append("%d노드 클리어" % int(outcome.get("clearedNodes", node_parts.size())))
	var loot_parts: Array[String] = []
	for raw_loot: Variant in outcome.get("loot", []) as Array:
		if raw_loot is not Dictionary:
			continue
		var loot := raw_loot as Dictionary
		loot_parts.append("%s ×%d" % [_item_display_name(str(loot.get("itemId", ""))), int(loot.get("count", 1))])
		if loot_parts.size() >= 2:
			break
	if not loot_parts.is_empty():
		result_parts.append("전리품 %s" % ", ".join(loot_parts))
	var region_reward: Dictionary = outcome.get("regionReward", {}) as Dictionary
	if _feedback_big_is_positive(region_reward):
		result_parts.append("지역 보상 골드 +%s" % _format_big(region_reward))
	var reward_fragment := str(outcome.get("rewardFragment", "")).strip_edges()
	if not reward_fragment.is_empty():
		result_parts.append("발견품 %s" % reward_fragment)
	if not result_parts.is_empty():
		lines.append("원정 결과 · %s" % " · ".join(result_parts))
	return lines


func _build_review_feedback_payload(review: Dictionary, activity_result: Dictionary) -> Dictionary:
	var awarded: Array = review.get("titles", []) as Array
	var details: Array[String] = []
	var kind := "review"
	var badge := "심사"
	var headline := "%d연차 %d시즌 심사 완료" % [int(review.get("year", 1)), int(review.get("season", 1))]
	var tone := "raised"
	if not awarded.is_empty():
		kind = "title"
		badge = "칭호"
		tone = "gold"
		var has_new_title := false
		var has_star_up := false
		for raw_title: Variant in awarded:
			if raw_title is not Dictionary:
				continue
			var title_data := raw_title as Dictionary
			var stars := int(title_data.get("stars", 1))
			has_new_title = has_new_title or stars <= 1
			has_star_up = has_star_up or stars > 1
			if details.size() < 2:
				details.append("칭호 %s · %s" % [str(title_data.get("name", title_data.get("id", "진로 칭호"))), str(title_data.get("rank", _career_rank(stars)))])
		# 칭호는 두 줄까지만 쓰고 나머지 수는 둘째 줄 끝에 붙여 심사 보상 줄의 자리를 지킨다.
		if awarded.size() > 2 and not details.is_empty():
			details[details.size() - 1] = "%s 외 %d개" % [details.back(), awarded.size() - 2]
		if has_new_title and has_star_up:
			headline = "새 칭호와 별 상승"
		elif has_star_up:
			headline = "진로 칭호 별 상승"
		else:
			headline = "새 진로 칭호 획득"

	details.append("심사 보상 · 명성 +%d · 정책 일치 %d%%" % [
		int(review.get("renownGained", 0)),
		int(round(float(review.get("policyFit", 0.0)) * 100.0)),
	])
	var tier_before := int(review.get("worldTierBefore", _state.get("worldTier", 1)))
	var tier_after := int(review.get("worldTierAfter", tier_before))
	if tier_after > tier_before:
		details.append("세계 티어 상승 · %d > %d" % [tier_before, tier_after])
	else:
		details.append("성과 · 도전 승리 %d · 계약 %d" % [int(review.get("challengeWins", 0)), int(review.get("completedContracts", 0))])
	if str(activity_result.get("kind", "")) == "challenge":
		var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
		if outcome.has("playerScore") and outcome.has("opponentScore"):
			details.append("직전 도전 · %.1f / %.1f%s" % [
				float(outcome.get("playerScore", 0.0)),
				float(outcome.get("opponentScore", 0.0)),
				" 승리" if bool(outcome.get("won", false)) else " 경험 축적",
			])
		var hint := str(outcome.get("hint", "")).strip_edges()
		if not bool(outcome.get("won", false)) and not hint.is_empty():
			details.append("다음 준비 · %s" % hint)
	# 심사와 함께 끝난 활동의 나머지 성장(칩 3개 밖)은 남는 자리에 보인다.
	var growth_line := _feedback_growth_line(activity_result.get("gains", {}) as Dictionary)
	if not growth_line.is_empty():
		details.append(growth_line)
	return {
		"kind": kind,
		"badge": badge,
		"tone": tone,
		"headline": headline,
		"floatingStats": _feedback_stat_tokens(activity_result.get("gains", {}) as Dictionary),
		"details": details,
	}


# 결과 창의 능력치 칩은 큰 순서로 3개까지다. 성장 줄은 칩이 못 보여 준 나머지 능력치만 담는다.
func _feedback_growth_line(gains: Dictionary) -> String:
	var parts := _feedback_stat_tokens(gains, 0).slice(3)
	return "그 외 성장 · %s" % " · ".join(parts) if not parts.is_empty() else ""


# limit 0이면 0이 아닌 변화 전부를 큰 순서로 돌려준다.
func _feedback_stat_tokens(gains: Dictionary, limit: int = 3) -> Array[String]:
	var keys: Array = gains.keys()
	keys.sort_custom(func(left: Variant, right: Variant) -> bool:
		return absf(float(gains[left])) > absf(float(gains[right]))
	)
	var parts: Array[String] = []
	for raw_key: Variant in keys:
		var value := float(gains[raw_key])
		if is_zero_approx(value):
			continue
		parts.append("%s %s%s" % [
			str(STAT_LABELS.get(str(raw_key), str(raw_key))),
			"+" if value > 0.0 else "",
			_feedback_number(value),
		])
		if limit > 0 and parts.size() >= limit:
			break
	return parts


func _feedback_reward_lines(activity_result: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var outcome: Dictionary = activity_result.get("outcome", {}) as Dictionary
	var challenge_reward: Dictionary = outcome.get("rewardGold", {}) as Dictionary
	# 도전의 활동 보상은 도전 보상 그 자체라(엔진이 같은 값을 준다) 한 번만 보인다.
	if str(activity_result.get("kind", "")) == "challenge" or _feedback_big_is_positive(challenge_reward):
		if _feedback_big_is_positive(challenge_reward):
			lines.append("도전 보상 · 골드 +%s" % _format_big(challenge_reward))
		return lines
	var reward: Dictionary = activity_result.get("reward", {}) as Dictionary
	if _feedback_big_is_positive(reward):
		lines.append("활동 보상 · 골드 +%s" % _format_big(reward))
	return lines


func _feedback_big_is_positive(value: Dictionary) -> bool:
	return float(value.get("mantissa", 0.0)) > 0.0


func _feedback_number(value: float) -> String:
	return "%.1f" % value if absf(value) < 100.0 else "%.0f" % value


func _feedback_activity_name(activity_result: Dictionary) -> String:
	var activity_id := str(activity_result.get("activityId", ""))
	if not activity_id.is_empty():
		return _activity_name_by_id(activity_id)
	var title := str(activity_result.get("title", "도전"))
	return title.trim_suffix(" 완료")


func _world_action_card(title: String, detail: String, activity_id: String, action_label: String, lock_reason: String = "") -> Control:
	var kind := _activity_kind(_activity_by_id(activity_id))
	var card := _card("transparent")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	var locked := not lock_reason.is_empty() and not _activity_in_progress(activity_id)
	title_row.add_child(_icon("lock" if locked else _kind_icon_name(kind)))
	var title_label := _label(title, 16, PixelTokens.INK_MUTED if locked else PixelTokens.INK)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_row.add_child(title_label)
	box.add_child(title_row)
	var detail_label := _label(detail, 16, PixelTokens.INK_MUTED)
	detail_label.max_lines_visible = 2
	box.add_child(detail_label)
	if kind == "adventure":
		var nodes := HBoxContainer.new()
		nodes.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
		for index in 3:
			nodes.add_child(_icon(["preset_explorer", "preset_martial", "preset_leader"][index]))
			var node_label := _label(["탐색", "조우", "보스"][index], 16, PixelTokens.INFO)
			node_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			node_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			nodes.add_child(node_label)
			if index < 2:
				var arrow := _label(">", 16, PixelTokens.INK_MUTED)
				arrow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				nodes.add_child(arrow)
		box.add_child(nodes)
	var conflicts := _expedition_conflicts(activity_id) if lock_reason.is_empty() else []
	if not lock_reason.is_empty():
		box.add_child(_lock_reason_label(activity_id, lock_reason))
	elif not conflicts.is_empty():
		var skip_line := _label(_expedition_conflict_text(conflicts, true), 16, PixelTokens.ACCENT)
		PixelText.wrap_at_spaces(skip_line)
		box.add_child(skip_line)
		action_label = "시험 빠지고 출발"
	var action := _button(action_label, _run_world_activity.bind(activity_id, _conflict_ids(conflicts) if kind == "adventure" else null), "primary" if lock_reason.is_empty() else "secondary", 48.0, "world_%s" % activity_id)
	action.icon = _icon_texture("play")
	action.disabled = not lock_reason.is_empty()
	action.add_to_group("critical_cta")
	box.add_child(action)
	card.add_child(box)
	return card


func _challenge_weight_summary(activity: Dictionary) -> String:
	var parts: Array[String] = []
	var weights: Dictionary = activity.get("challengeWeights", {}) as Dictionary
	var keys := weights.keys()
	keys.sort_custom(func(left, right): return float(weights[left]) > float(weights[right]))
	for key in keys.slice(0, 3):
		parts.append("%s %d%%" % [str(STAT_LABELS.get(str(key), key)), int(float(weights[key]) * 100.0)])
	return " · ".join(parts)


func _challenge_rank_name(rank: String) -> String:
	return str({
		"participation": "참가", "pass": "통과", "honors": "우수",
	}.get(rank, rank))


func _contract_modifier_name(modifier_id: String) -> String:
	return str({
		"low_energy": "에너지 25 이상", "high_quality": "고품질 수행", "no_repeat": "연속 반복 금지",
		"risk_bonus": "위험 임무 무부상", "budget_guard": "최소 보유금 준수", "mastery_focus": "숙련 집중",
		"limited_slots": "기한 내 완료", "balanced_tags": "분야 다양성", "stress_guard": "스트레스 상한 준수",
		"community_bonus": "관계 성장",
	}.get(modifier_id, modifier_id.replace("_", " ")))


func _setting_toggle(title: String, description: String, key: String, value: bool) -> Control:
	var card := _card("raised")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(_label(title, 18, PixelTokens.INK))
	text_box.add_child(_label(description, 16, PixelTokens.INK_MUTED))
	row.add_child(text_box)
	var toggle := CheckButton.new()
	toggle.custom_minimum_size = Vector2(64, 48)
	toggle.button_pressed = value
	toggle.set_meta("ui_id", "toggle_%s" % key)
	toggle.mouse_filter = Control.MOUSE_FILTER_PASS
	toggle.toggled.connect(_toggle_setting.bind(key))
	row.add_child(toggle)
	card.add_child(row)
	return card


# 정책 값 스테퍼: 이름, 설명, −/값/+ 버튼. 목록을 세로로 밀다가 값이 바뀌지 않도록 슬라이더 대신 쓴다(설계 D4).
func _policy_slider(title: String, description: String, key: String, value: float, minimum: float, maximum: float, step: float, formatter: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	row.set_meta("policy_key", key)
	row.set_meta("policy_value", value)
	row.add_to_group("policy_stepper")
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 2)
	var title_label := _label(title, 16, PixelTokens.INK)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_box.add_child(title_label)
	if not description.is_empty():
		text_box.add_child(_label(description, 16, PixelTokens.INK_MUTED))
	row.add_child(text_box)
	var minus := _button("", Callable(), "secondary", 44.0, "step_%s_minus" % key)
	minus.icon = _icon_texture("minus")
	minus.tooltip_text = "%s 줄이기" % title
	var value_label := _label(str(formatter.call(value)), 16, PixelTokens.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	var plus := _button("", Callable(), "secondary", 44.0, "step_%s_plus" % key)
	plus.icon = _icon_texture("plus")
	plus.tooltip_text = "%s 늘리기" % title
	row.set_meta("policy_value_label", value_label)
	for step_button in [minus, plus]:
		step_button.theme_type_variation = "PixelButtonCompactSecondary"
		step_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_button.custom_minimum_size.x = 44.0
		step_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	minus.pressed.connect(_step_policy.bind(row, -step, minimum, maximum, formatter))
	plus.pressed.connect(_step_policy.bind(row, step, minimum, maximum, formatter))
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.custom_minimum_size.x = 72.0
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(minus)
	row.add_child(value_label)
	row.add_child(plus)
	row.set_meta("policy_buttons", [minus, plus])
	_update_stepper_buttons(row, value, minimum, maximum)
	return row


func _step_policy(row: Control, delta: float, minimum: float, maximum: float, formatter: Callable) -> void:
	var key := str(row.get_meta("policy_key", ""))
	var next_value := clampf(float(row.get_meta("policy_value", 0.0)) + delta, minimum, maximum)
	next_value = snappedf(next_value, absf(delta))
	row.set_meta("policy_value", next_value)
	_on_policy_slider_changed(next_value, key, row.get_meta("policy_value_label") as Label, formatter)
	_update_stepper_buttons(row, next_value, minimum, maximum)


func _update_stepper_buttons(row: Control, value: float, minimum: float, maximum: float) -> void:
	var buttons: Array = row.get_meta("policy_buttons", [])
	if buttons.size() == 2:
		(buttons[0] as Button).disabled = value <= minimum + 0.0001
		(buttons[1] as Button).disabled = value >= maximum - 0.0001


func _stat_card(title: String, value: float) -> Control:
	var card := _card("transparent")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	var title_label := _label(title, 16, PixelTokens.INK)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	row.add_child(_label(_format_number(value), 16, PixelTokens.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT))
	box.add_child(row)
	box.add_child(_gauge("stat", fmod(value, 100.0) / 100.0))
	card.add_child(box)
	return card


func _resource_card(title: String, value: String, accent: Color) -> Control:
	var card := _card("transparent")
	card.custom_minimum_size.y = 64.0
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.add_child(_label(title, 16, PixelTokens.INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(value, 16, PixelTokens.INK, HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(box)
	return card


# 홈 미터 한 칸: 아이콘, 이름, 값, 분할 게이지
func _meter_cell(kind: String, title: String, value: float, maximum: float) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	row.add_child(_icon(kind))
	var name_label := _label(title, 16, PixelTokens.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := _label("%d" % int(value), 16, PixelTokens.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(value_label)
	box.add_child(row)
	box.add_child(_gauge(kind, value / maximum))
	return box


# 탭 화면의 구획 제목은 어두운 나무 바탕 위에 놓이므로 밝은 글자를 쓴다. 시트(양피지) 안에서는 _open_sheet가 잉크색으로 바꾼다.
func _section_heading(title: String, subtitle: String = "") -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var title_label := _label(title, 24, PixelTokens.ON_STRIP)
	title_label.set_meta("heading_role", "title")
	box.add_child(title_label)
	if not subtitle.is_empty():
		var subtitle_label := _label(subtitle, 16, PixelTokens.ON_STRIP_MUTED)
		subtitle_label.set_meta("heading_role", "subtitle")
		box.add_child(subtitle_label)
	return box


func _ink_headings(root: Node) -> void:
	for node: Node in root.find_children("*", "Label", true, false):
		match str(node.get_meta("heading_role", "")):
			"title": (node as Label).add_theme_color_override("font_color", PixelTokens.INK)
			"subtitle": (node as Label).add_theme_color_override("font_color", PixelTokens.INK_MUTED)


func _chip(text_value: String, _accent: Color) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.theme_type_variation = PixelTheme.panel_variation("chip")
	var label := _label(text_value, 16, PixelTokens.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.add_child(label)
	return chip


# tone: 기존 화면이 쓰던 카드 톤을 픽셀 창 종류로 옮긴다.
func _card(tone: String = "navy") -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var variation := {
		"gold": "window_gold", "coral": "window_accent", "transparent": "inset", "selected": "window_selected",
		"window": "window", "inset": "inset",
	}.get(tone, "window") as String
	card.theme_type_variation = PixelTheme.panel_variation(variation)
	return card


func _button(label_text: String, callback: Callable = Callable(), variant: String = "secondary", min_height: float = 48.0, ui_id: String = "") -> Button:
	var button := Button.new()
	button.text = label_text
	if not ui_id.is_empty():
		button.set_meta("ui_id", ui_id)
	# 목록 안 버튼 위에서 시작한 드래그도 부모 ScrollContainer가 받아 스크롤하게 한다.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size.y = maxf(44.0, min_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = label_text.replace("\n", " · ")
	button.set_meta("royal_variant", variant)
	button.add_to_group("royal_button")
	button.theme_type_variation = PixelTheme.button_variation(variant)
	button.pressed.connect(_on_button_pressed.bind(label_text))
	if callback.is_valid():
		button.pressed.connect(callback)
	for marker in ["자동 1회", "즉시 실행", "이 활동 1회", "원정 시작", "참가하기", "오프라인 결과", "이어하기", "구매", "장착", "사용", "판매", "계약 고정"]:
		if label_text.contains(marker):
			button.add_to_group("critical_cta")
			break
	return button


# 글자 크기는 픽셀 폰트 설계 크기의 정수배만 쓴다: 본문 16(Neo둥근모), 제목 24(Galmuri11 Bold), 큰 숫자 32(Neo둥근모).
func _label(text_value: String, font_size: int = 16, color: Color = PixelTokens.INK, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	if font_size >= 28:
		label.add_theme_font_size_override("font_size", PixelTheme.LARGE_SIZE)
	elif font_size >= 20:
		label.add_theme_font_override("font", PixelTheme.title_font())
		label.add_theme_font_size_override("font_size", PixelTheme.TITLE_SIZE)
	else:
		label.add_theme_font_size_override("font_size", PixelTheme.BODY_SIZE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


# 1배 도트 아이콘을 2배로 키운 텍스처.
func _icon_texture(icon_name: String) -> Texture2D:
	return PixelTheme.doubled_texture(ICON_DIR + icon_name + ".png")


func _icon(icon_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _icon_texture(icon_name)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _gauge(kind: String, ratio: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.theme_type_variation = PixelTheme.gauge_variation(kind)
	bar.custom_minimum_size.y = 12.0
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = clampf(ratio, 0.0, 1.0) * 100.0
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	return bar


# 받침 유무로 조사를 고른다. 예: _josa("응용 마력학", "을", "를") → "응용 마력학을"
func _josa(word: String, with_final: String, without_final: String) -> String:
	if word.is_empty():
		return word
	var code := word.unicode_at(word.length() - 1)
	var has_final := code >= 0xAC00 and code <= 0xD7A3 and (code - 0xAC00) % 28 != 0
	return word + (with_final if has_final else without_final)


func _preset_icon(preset_id: String) -> String:
	return "magic" if preset_id == "scholar" else "preset_" + preset_id


func _kind_icon_name(kind: String) -> String:
	match kind:
		"job": return "coin"
		"rest": return "moon"
		"adventure": return "world"
		"challenge": return "record"
		_: return "activity"


func _activity_icon_name() -> String:
	var current_id := str(_read(["activeTask", "activityId"], _read(["activeTask", "id"], "")))
	if current_id.contains("MAGIC"):
		return "magic"
	match str(_activity_by_id(current_id).get("kind", "")):
		"job": return "coin"
		"rest": return "home"
		"adventure": return "world"
		"challenge": return "record"
		_: return "activity"


func _load_activities() -> Array:
	var loaded := _load_json_array("res://data/activities.json")
	if not loaded.is_empty():
		return loaded
	return FALLBACK_ACTIVITIES.duplicate(true)


func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in ["activities", "items", "data"]:
			if typeof(parsed.get(key, null)) == TYPE_ARRAY:
				return parsed[key]
	return []


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _activity_kind(activity: Dictionary) -> String:
	var kind := str(activity.get("kind", "education"))
	if kind in ["exam", "sport", "contest", "league"]:
		return "challenge"
	return kind


func _activity_by_id(activity_id: String) -> Dictionary:
	for activity in _activities:
		if typeof(activity) == TYPE_DICTIONARY and str(activity.get("id", "")) == activity_id:
			return activity
	return {}


# 진행 중인 시험은 다시 실행할 수 없지만 잠긴 것이 아니다. 행에는 진행 중으로 보이고 버튼만 막는다.
func _activity_in_progress(activity_id: String) -> bool:
	return str(_read(["activeTask", "activityId"], "")) == activity_id and _activity_kind(_activity_by_id(activity_id)) == "challenge"


func _activity_lock_reason(activity_id: String) -> String:
	if _activity_in_progress(activity_id):
		var remaining := int(_read(["activeTask", "remainingSlots"], 0))
		return "진행 중 · %d일 남음" % remaining if remaining > 0 else "진행 중"
	var requirement := _activity_requirement_reason(activity_id)
	var decision = _read(["lastPlannerDecision"], {})
	if typeof(decision) == TYPE_DICTIONARY:
		var rejected = decision.get("rejected", {})
		if typeof(rejected) == TYPE_DICTIONARY and rejected.has(activity_id):
			# 단계가 열리기 전에 내린 결정의 해금 잠금은 다음 결정 전까지 남아 있으므로, 이미 열린 활동에는 쓰지 않는다.
			var raw := str(rejected[activity_id])
			# 직접 고른 원정은 시험 일정보다 먼저 하므로(이슈 #12), 자동 판단의 시험 겹침 대신 지금 직접 실행할 때의 판단을 쓴다.
			if raw.begins_with("예정 도전") and _activity_kind(_activity_by_id(activity_id)) == "adventure":
				raw = _manual_rejection(activity_id)
				if raw.is_empty():
					return requirement
			var stale_stage_lock := raw.begins_with("해금 단계") and _activity_open(_activity_by_id(activity_id))
			# 결정 뒤 골드가 늘었거나 시험 일정이 지나 이미 풀린 거절도 다음 결정 전까지 남아 있으므로 쓰지 않는다.
			var stale_gold := (raw.begins_with("비용 지불") or raw.begins_with("최소 보유금")) and _gold_shortfall(activity_id) <= 0.0
			var stale_schedule := raw.begins_with("예정 도전") and _schedule_free_slot(activity_id) == int(_read(["time", "slot"], 0)) + 1
			if not stale_stage_lock and not stale_gold and not stale_schedule:
				return _friendly_rejection(raw, activity_id)
	return requirement


# 잠금 이유 한 줄. 진행 중은 잠금이 아니므로 "잠금" 표시와 경고색을 쓰지 않는다.
func _lock_reason_label(activity_id: String, lock_reason: String) -> Label:
	if _activity_in_progress(activity_id):
		return _label(lock_reason, 16, PixelTokens.INK)
	return _label("잠금 · %s" % lock_reason, 16, PixelTokens.NEGATIVE)


# 플래너·엔진의 거절 문구를 플레이어가 이해할 수 있는 말로 바꾼다. 구체적인 능력치·티어 조건이 있으면 그것을 먼저 보여 준다.
func _friendly_rejection(raw: String, activity_id: String) -> String:
	var number := RegEx.create_from_string("(\\d+)").search(raw)
	var slot := number.get_string(1) if number != null else ""
	if raw.begins_with("해금 단계"):
		return "아직 열리지 않았어요"
	if raw.begins_with("잠금 조건"):
		var requirement := _activity_requirement_reason(activity_id)
		return requirement if not requirement.is_empty() else "조건을 채우면 열려요"
	if raw.begins_with("시즌 일정"):
		return "시즌 %s일째에 열려요" % slot
	if raw.begins_with("예정 도전"):
		# 다음 시험 전에 끝나지 않는 활동은 막힌다. 긴 활동은 뒤 시험에도 걸리므로 실제로 고를 수 있는 날을 계산해 알린다.
		return _schedule_free_text(activity_id, slot)
	if raw.begins_with("성장 정책에서 제외"):
		return "금지 태그에 들어 있어요"
	if raw.begins_with("회복 활동"):
		return "지금은 회복이 먼저예요"
	if raw.begins_with("비용 지불"):
		# 비용을 내고도 최소 보유금이 남아야 실행되므로(7단계 전에는 보이지 않는 규칙) 둘을 합쳐 모자란 골드를 알린다.
		return _gold_shortfall_text(activity_id)
	if raw.begins_with("최소 보유금"):
		return "최소 보유금 아래로 내려가요" if _feature_open("rules") else _gold_shortfall_text(activity_id)
	if raw.begins_with("선행 활동 후"):
		# 수동 1회는 진행 중이던 활동을 먼저 끝낸다. 그 사이 규칙이 바뀌어 밀리면 플래너가 남긴 이유를 보여 준다.
		var pushed_back := _planner_rejection(activity_id)
		if not pushed_back.is_empty() and not pushed_back.begins_with("선행 활동 후"):
			return _friendly_rejection(pushed_back, activity_id)
		return "앞 활동을 마치는 사이 조건이 바뀌었어요"
	if raw.begins_with("요청 활동 실행 제한"):
		return "지금은 실행할 수 없어요"
	return raw


func _manual_rejection(activity_id: String) -> String:
	if _engine == null or not _engine.has_method("manual_rejection_reason"):
		return ""
	return str(_engine.call("manual_rejection_reason", activity_id, _state))


# 직접 고른 원정이 덮어 빠지게 되는 시험 id(원정이 아니거나 겹치지 않으면 빈 배열).
func _expedition_conflicts(activity_id: String) -> Array:
	if _engine == null or not _engine.has_method("activity_schedule_conflicts"):
		return []
	return _engine.call("activity_schedule_conflicts", activity_id, _state) as Array


# 겹치는 첫 시험의 날짜와 이름. 다음 시즌 시험이면 "다음 시즌"을 붙인다.
# long이면 "24일째 개척 원정 리그와 겹쳐요. 출발하면 그 시험에 빠져요", 아니면 "24일째 시험에 빠져요"(다음 시즌이면 "다음 시즌 시험에 빠져요").
func _expedition_conflict_text(conflicts: Array, long: bool) -> String:
	if conflicts.is_empty():
		return ""
	if not long:
		return _expedition_conflict_day(conflicts[0] as Dictionary) + " 시험에 빠져요" if not _expedition_conflict_next_season(conflicts[0] as Dictionary) else "다음 시즌 시험에 빠져요"
	var parts: Array[String] = []
	for index: int in mini(2, conflicts.size()):
		var conflict: Dictionary = conflicts[index] as Dictionary
		parts.append("%s %s" % [_expedition_conflict_day(conflict), _activity_name_by_id(str(conflict.get("id", "")))])
	var subject := ", ".join(parts)
	if conflicts.size() > 2:
		subject += " 외 %d개" % (conflicts.size() - 2)
	return "%s 겹쳐요. 출발하면 그 시험에 빠져요" % _josa(subject, "과", "와")


# "24일째" 또는 다음 시즌이면 "다음 시즌 4일째".
func _expedition_conflict_day(conflict: Dictionary) -> String:
	var per_season := maxi(1, int(_runtime_config.get("slotsPerSeason", 28)))
	var day := (int(conflict.get("slot", 1)) - 1) % per_season + 1
	return ("다음 시즌 %d일째" if _expedition_conflict_next_season(conflict) else "%d일째") % day


func _expedition_conflict_next_season(conflict: Dictionary) -> bool:
	var per_season := maxi(1, int(_runtime_config.get("slotsPerSeason", 28)))
	return (int(conflict.get("slot", 1)) - 1) / per_season > int(_read(["time", "slot"], 0)) / per_season


func _expedition_conflicts_changed(activity_id: String, shown_conflicts: Variant) -> bool:
	return shown_conflicts is Array and _conflict_ids(_expedition_conflicts(activity_id)) != (shown_conflicts as Array)


func _conflict_ids(conflicts: Array) -> Array:
	var ids: Array = []
	for conflict: Variant in conflicts:
		ids.append(str((conflict as Dictionary).get("id", "")))
	return ids


func _planner_rejection(activity_id: String) -> String:
	var decision = _read(["lastPlannerDecision"], {})
	if typeof(decision) != TYPE_DICTIONARY:
		return ""
	var rejected = (decision as Dictionary).get("rejected", {})
	return str((rejected as Dictionary).get(activity_id, "")) if typeof(rejected) == TYPE_DICTIONARY else ""


# 실행하려면 더 모아야 하는 골드: 지금 비용(세계 티어 반영) + 최소 보유금 - 보유 골드.
func _gold_shortfall(activity_id: String) -> float:
	var cost := _big_to_number(_activity_tier_value(activity_id, "cost"))
	var gold := _big_to_number(_read(["bigValues", "gold"], {"mantissa": 0, "exponent": 0}))
	return cost + _reserve_gold_number() - gold


func _gold_shortfall_text(activity_id: String) -> String:
	var shortfall := _gold_shortfall(activity_id)
	if shortfall <= 0.0:
		return "골드가 부족해요"
	return "골드 %sG 더 필요" % _format_number(ceilf(shortfall))


func _schedule_free_slot(activity_id: String) -> int:
	if _engine == null or not _engine.has_method("activity_schedule_free_slot"):
		return -1
	var frame := Engine.get_process_frames()
	if frame != _free_slot_memo_frame:
		_free_slot_memo.clear()
		_free_slot_memo_frame = frame
	var key := "%s|%d|%d|%d" % [activity_id, int(_read(["time", "slot"], 0)), int(_state.get("worldTier", 1)), _unlock_stage()]
	if not _free_slot_memo.has(key):
		_free_slot_memo[key] = int(_engine.call("activity_schedule_free_slot", activity_id, _state))
	return int(_free_slot_memo[key])


# 고를 수 있게 되는 날. 이번 시즌이면 "N일째부터 열려요", 다음 시즌이면 "다음 시즌 N일째부터", 모르면 겹치는 시험 날.
func _schedule_free_text(activity_id: String, exam_day: String) -> String:
	var free_slot := _schedule_free_slot(activity_id)
	var per_season := maxi(1, int(_runtime_config.get("slotsPerSeason", 28)))
	var season_now := int(_read(["time", "slot"], 0)) / per_season
	if free_slot > 0:
		var free_season := (free_slot - 1) / per_season
		var day := (free_slot - 1) % per_season + 1
		if free_season == season_now:
			return "%d일째부터 열려요" % day
		if free_season == season_now + 1:
			return "다음 시즌 %d일째부터" % day
	return "시즌 %s일째 시험과 겹쳐요" % exam_day


func _activity_requirement_reason(activity_id: String) -> String:
	var activity := _activity_by_id(activity_id)
	var requires: Dictionary = activity.get("requires", {}) as Dictionary
	for key in (requires.get("gte", {}) as Dictionary):
		var actual := float(_read(["stats", str(key)], _read(["meters", str(key)], 0.0)))
		if actual < float((requires.get("gte", {}) as Dictionary)[key]):
			return "%s %.0f 필요" % [str(STAT_LABELS.get(str(key), key)), float((requires.get("gte", {}) as Dictionary)[key])]
	var tier_requirement = requires.get("worldTier", 0)
	var required_tier := int((tier_requirement as Dictionary).get("gte", 0)) if tier_requirement is Dictionary else int(tier_requirement)
	if int(_state.get("worldTier", 1)) < required_tier:
		return "세계 티어 %d 필요" % required_tier
	return ""


func _activity_name_by_id(activity_id: String) -> String:
	var activity := _activity_by_id(activity_id)
	if not activity.is_empty():
		return str(activity.get("name", activity_id))
	return activity_id.replace("_", " ")


func _current_activity_name() -> String:
	var task = _read(["activeTask"], {})
	if typeof(task) == TYPE_DICTIONARY:
		if not str(task.get("name", "")).is_empty():
			return str(task["name"])
		var activity_id := str(task.get("activityId", task.get("id", "REST_HOME")))
		return _activity_name_by_id(activity_id)
	return "다음 활동 준비"


# ── 단계적 해금(GDD §2.2) ─────────────────────────────────────────
# 엔진 없이 그리는 시연 상태(unlocks 없음)는 모든 기능을 연 화면으로 본다.
func _unlock_stage() -> int:
	var unlocks = _state.get("unlocks")
	if typeof(unlocks) != TYPE_DICTIONARY:
		return 99
	return int((unlocks as Dictionary).get("stage", 1))


func _feature_stage(feature_id: String) -> int:
	if _engine != null and _engine.has_method("get_content_db"):
		var db = _engine.call("get_content_db")
		if db is ContentDB:
			return (db as ContentDB).feature_stage(feature_id)
	return 1


func _feature_open(feature_id: String) -> bool:
	return _unlock_stage() >= _feature_stage(feature_id)


func _activity_open(activity: Dictionary) -> bool:
	return _unlock_stage() >= int((activity.get("requires", {}) as Dictionary).get("stage", 1))


func _unlock_status() -> Dictionary:
	if _engine != null and _engine.has_method("unlock_status") and typeof(_state.get("unlocks")) == TYPE_DICTIONARY:
		return _engine.call("unlock_status") as Dictionary
	return {}


func _unlock_label(stage_number: int) -> String:
	if _engine != null and _engine.has_method("unlock_stage_entry"):
		return str((_engine.call("unlock_stage_entry", stage_number) as Dictionary).get("label", ""))
	return ""


# 다음 단계 예고를 둘 자리: 탭을 열면 탭, 월드를 열면 홈, 세부 규칙을 열면 계획, 그 밖에는 활동 목록.
func _unlock_teaser_place() -> String:
	var next: Dictionary = _unlock_status().get("next", {}) as Dictionary
	if next.is_empty():
		return ""
	var features: Array = next.get("features", []) as Array
	for tab_id in ["plan", "growth", "record"]:
		if features.has(tab_id):
			return "tab"
	if features.has("world"):
		return "home"
	if features.has("rules"):
		return "plan"
	return "activity"


func _unlock_remaining_text() -> String:
	var next: Dictionary = _unlock_status().get("next", {}) as Dictionary
	var remaining: Dictionary = next.get("remaining", {}) as Dictionary
	if remaining.has("activities"):
		return "활동 %d회 더" % maxi(1, int(remaining["activities"]))
	if remaining.has("slot"):
		return "%d일 뒤" % maxi(1, int(remaining["slot"]))
	if remaining.has("seasonReviews"):
		# 시즌 심사까지 남은 날로 보여 준다(심사는 시즌의 마지막 날).
		var per_season := maxi(1, _config_int("slotsPerSeason", 28))
		var slot := int(_read(["time", "slot"], 0))
		var target := (int(slot / per_season) + maxi(1, int(remaining["seasonReviews"]))) * per_season
		return "%d일 뒤" % maxi(1, target - slot)
	return ""


func _unlock_teaser_sentence() -> String:
	var next: Dictionary = _unlock_status().get("next", {}) as Dictionary
	if next.is_empty():
		return ""
	return "곧 열림 · %s · %s" % [str(next.get("label", "")), _unlock_remaining_text()]


func _show_unlock_teaser() -> void:
	_show_toast(_unlock_teaser_sentence())


func _unlock_teaser_button(height: float, title: String) -> Button:
	var teaser := _button("%s\n%s" % [title, _unlock_remaining_text()], _show_unlock_teaser, "secondary", height, "unlock_teaser")
	teaser.icon = _icon_texture("lock")
	teaser.alignment = HORIZONTAL_ALIGNMENT_LEFT
	teaser.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	teaser.tooltip_text = _unlock_teaser_sentence()
	return teaser


func _unlock_teaser_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP_SMALL)
	row.set_meta("ui_id", "unlock_teaser_row")
	row.add_child(_icon("lock"))
	var text := _label(_unlock_teaser_sentence(), 16, PixelTokens.INK_MUTED)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


func _refresh_navigation() -> void:
	for tab_id in _nav_buttons:
		(_nav_buttons[tab_id] as Button).visible = _feature_open(str(tab_id))
	if _unlock_teaser_tab != null:
		var show_teaser := _unlock_teaser_place() == "tab"
		_unlock_teaser_tab.visible = show_teaser
		if show_teaser:
			var next: Dictionary = _unlock_status().get("next", {}) as Dictionary
			var tab_name := ""
			for definition in TABS:
				if tab_name.is_empty() and (next.get("features", []) as Array).has(str(definition["id"])):
					tab_name = str(definition["label"])
			_unlock_teaser_tab.text = "%s\n%s" % [tab_name, _unlock_remaining_text()]
			_unlock_teaser_tab.tooltip_text = _unlock_teaser_sentence()
	_layout_navigation()
	if _current_tab != "" and not _feature_open(_current_tab):
		_show_tab("home")


# 보이는 탭 수가 2~6개로 바뀌어도 탭 너비와 위치를 짝수 픽셀로 맞춘다(PX-05).
func _layout_navigation() -> void:
	_layout_even_row(_nav_row)


# 가로 줄의 보이는 버튼을 짝수 너비로 나눈다. 마지막 버튼이 남는 짝수 픽셀을 가진다.
func _layout_even_row(row: HBoxContainer) -> void:
	if row == null or not is_instance_valid(row):
		return
	var visible_buttons: Array[Control] = []
	for child in row.get_children():
		if child is Control and (child as Control).visible:
			visible_buttons.append(child as Control)
	if visible_buttons.is_empty() or row.size.x <= 0.0:
		return
	var separation := row.get_theme_constant("separation")
	var available := int(row.size.x) - separation * (visible_buttons.size() - 1)
	var width := int(floor(float(available) / visible_buttons.size() / 2.0)) * 2
	var last_width := available - width * (visible_buttons.size() - 1)
	for index in visible_buttons.size():
		var button := visible_buttons[index]
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size.x = width if index < visible_buttons.size() - 1 else last_width - last_width % 2


# 2열 격자에 버튼이 하나만 남으면 한 열로 바꿔 짝수 너비를 지킨다.
func _fit_grid_columns(grid: GridContainer) -> void:
	if grid.get_child_count() == 1:
		grid.columns = 1


# 새 단계가 열리면 알림 띠를 한 번 띄우고 확인 상태를 저장한다. 오프라인 정산은 정산 시트가 대신 보여 준다.
func _announce_unlocks() -> void:
	_show_unlock_notice(_take_unlock_notice())


# 접속 중에 새로 열린 단계를 확인 처리하고 알릴 문구("새로 열림 · …")를 돌려준다. 없으면 빈 문자열.
func _take_unlock_notice() -> String:
	var status := _unlock_status()
	if status.is_empty():
		return ""
	var stage_number := int(status.get("stage", 1))
	var announced := int(status.get("announced", stage_number))
	if stage_number <= announced:
		return ""
	var labels: Array[String] = []
	for opened in range(announced + 1, stage_number + 1):
		var label := _unlock_label(opened)
		if not label.is_empty():
			labels.append(label)
	_acknowledge_unlocks("online")
	_page_dirty = true
	return "새로 열림 · %s" % ", ".join(labels) if not labels.is_empty() else ""


func _show_unlock_notice(notice: String) -> void:
	if notice.is_empty():
		return
	_unlock_notice_text = notice
	_unlock_notice_until = Time.get_ticks_msec() + 2200
	_show_toast(_unlock_notice_text)


# 오프라인 정산(받기와 앱 시작·복귀의 경계 정산)으로 열린 단계는 알림 띠 대신 정산 시트 목록으로 보여 준다.
# 경계 정산은 계약상 0 slot이라 보통 비어 있지만, 같은 처리로 묶어 띠가 뜨지 않게 한다.
func _absorb_offline_unlocks(result: Variant) -> Array[String]:
	var labels: Array[String] = []
	if typeof(result) != TYPE_DICTIONARY:
		return labels
	for opened: Variant in (result as Dictionary).get("newUnlocks", []) as Array:
		labels.append(_unlock_label(int(opened)))
	if not labels.is_empty():
		_acknowledge_unlocks("offline")
		if not (result as Dictionary).has("changes"):
			var summary: Dictionary = (_state.get("lastOfflineSummary", {}) as Dictionary).duplicate(true)
			summary["unlockLabels"] = labels
			_state["lastOfflineSummary"] = summary
	return labels


func _acknowledge_unlocks(source: String) -> void:
	if source == "offline":
		# 오프라인으로 연 단계는 띠를 띄우지 않으므로, 직전 온라인 알림도 다음 알림에 붙이지 않는다.
		_unlock_notice_until = 0
	if _engine == null or not _engine.has_method("acknowledge_unlocks"):
		return
	var unlocks = _state.get("unlocks")
	var before := int((unlocks as Dictionary).get("announced", 1)) if typeof(unlocks) == TYPE_DICTIONARY else 1
	_engine.call("acknowledge_unlocks")
	var stage_number := int((unlocks as Dictionary).get("stage", 1)) if typeof(unlocks) == TYPE_DICTIONARY else 1
	if typeof(unlocks) == TYPE_DICTIONARY:
		(unlocks as Dictionary)["announced"] = stage_number
	_track_event(&"feature_unlocked", {"stage": stage_number, "fromStage": before, "slot": int(_read(["time", "slot"], 0)), "source": source})
	_persist_silently()


# 화면 첫 진입 안내: 기능이 열려 있고 아직 보지 않았으면 구획 아래에 한 번 보여 준다.
func _add_tip(body: VBoxContainer, feature_id: String) -> void:
	var status := _unlock_status()
	if status.is_empty() or not _feature_open(feature_id) or not _engine.has_method("unlock_tip"):
		return
	var text := str(_engine.call("unlock_tip", feature_id))
	if text.is_empty():
		return
	var screen := str(TIP_SCREEN.get(feature_id, feature_id))
	var showing := str(_tips_showing.get(screen, ""))
	var seen: Array = status.get("tipsSeen", []) as Array
	if showing != feature_id and (seen.has(feature_id) or not showing.is_empty()):
		return
	if showing.is_empty():
		_tips_showing[screen] = feature_id
		_engine.call("mark_unlock_tip_seen", feature_id)
		var unlocks = _state.get("unlocks")
		if typeof(unlocks) == TYPE_DICTIONARY:
			var state_seen = (unlocks as Dictionary).get("tipsSeen", [])
			if typeof(state_seen) == TYPE_ARRAY and not (state_seen as Array).has(feature_id):
				(state_seen as Array).append(feature_id)
		_persist_silently()
	var tip := PanelContainer.new()
	tip.theme_type_variation = PixelTheme.panel_variation("inset")
	tip.mouse_filter = Control.MOUSE_FILTER_PASS
	tip.set_meta("ui_id", "tip_%s" % feature_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PixelTokens.GAP)
	var tip_text := _label(text, 16, PixelTokens.INK)
	tip_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tip_text)
	var ok := _button("알겠어요", _dismiss_tip.bind(feature_id), "secondary", 44.0, "tip_ok_%s" % feature_id)
	ok.theme_type_variation = "PixelButtonCompactSecondary"
	ok.custom_minimum_size.x = 96.0
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ok)
	tip.add_child(row)
	body.add_child(tip)


func _dismiss_tip(feature_id: String) -> void:
	# 같은 화면에서 기다리던 다음 안내는 닫은 뒤 바로 보인다.
	_tips_showing.erase(str(TIP_SCREEN.get(feature_id, feature_id)))
	var sheet_kind := str({"world": "world", "league": "world", "shop": "shop", "events": "event"}.get(feature_id, ""))
	if not sheet_kind.is_empty() and _find_open_sheet(sheet_kind):
		_open_sheet(sheet_kind)
	else:
		_render_current_page()


func _find_open_sheet(kind: String) -> bool:
	if _modal_layer == null:
		return false
	for child in _modal_layer.get_children():
		if not child.is_queued_for_deletion() and str(child.get_meta("screen_id", "")) == kind:
			return true
	return false


# 현재 활동 이유 줄에 아직 열리지 않은 개념을 쓰지 않는다(AC-UNLOCK-12).
func _reason_concept_open(text: String) -> bool:
	for pair in [["고정 계약", "contracts"], ["위험 부담", "rules"], ["프리셋 선호", "plan"]]:
		if text.begins_with(str(pair[0])) and not _feature_open(str(pair[1])):
			return false
	return true


# 플래너 이유는 "성장 방향 +1.450"처럼 점수가 붙어 온다. 화면에는 이유 이름만 보여 준다.
func _reason_label_text(raw: String) -> String:
	return RegEx.create_from_string("\\s*[+-]\\d+(\\.\\d+)?$").sub(raw.strip_edges(), "").strip_edges()


func _planner_reason() -> String:
	var result: Array[String] = []
	var decision = _read(["lastPlannerDecision"], {})
	if typeof(decision) == TYPE_DICTIONARY:
		var decision_reasons = decision.get("reasons", [])
		if typeof(decision_reasons) == TYPE_ARRAY:
			for reason in decision_reasons:
				var text := _reason_label_text(str(reason.get("text", reason)) if typeof(reason) == TYPE_DICTIONARY else str(reason))
				if not _reason_concept_open(text):
					continue
				text = str(REASON_DISPLAY.get(text, text))
				if not text.is_empty() and not result.has(text):
					result.append(text)
				if result.size() == 3:
					break
	var task = _read(["activeTask"], {})
	if result.is_empty() and typeof(task) == TYPE_DICTIONARY and not str(task.get("reason", "")).is_empty():
		result.append(str(task["reason"]))
	var legacy_reasons = _state.get("selectionReasons", [])
	if result.size() < 3 and typeof(legacy_reasons) == TYPE_ARRAY:
		for reason in legacy_reasons:
			var text := str(reason.get("text", reason)) if typeof(reason) == TYPE_DICTIONARY else str(reason)
			if not text.is_empty() and not result.has(text):
				result.append(text)
			if result.size() == 3:
				break
	if not result.is_empty():
		return " · ".join(result)
	return "%s 방향 · 예산 안전 · 최근 다양성" % _preset_name(_policy_preset())


func _policy_preset() -> String:
	return str(_read(["growthPolicy", "preset"], "balanced"))


func _preset_name(preset_id: String) -> String:
	for preset in PRESETS:
		if str(preset["id"]) == preset_id:
			return str(preset["name"])
	return "균형"


func _season_slot() -> int:
	return posmod(int(_read(["time", "slot"], 0)), maxi(1, _config_int("slotsPerSeason", 28)))


func _profile_environment() -> String:
	var current_id := str(_read(["activeTask", "activityId"], _read(["activeTask", "id"], "")))
	var activity := _activity_by_id(current_id)
	var kind := str(activity.get("kind", ""))
	if kind == "job":
		return "city"
	if kind == "adventure":
		return "forest"
	if kind == "challenge":
		var tags: Array = activity.get("tags", []) as Array
		return "arena" if tags.has("sport") or tags.has("contest") or tags.has("league") else "library"
	if kind == "education":
		return "library"
	if kind == "rest":
		return "city" if current_id == "REST_WALK" else ("forest" if current_id in ["REST_TRIP", "REST_RESORT"] else "academy")
	match _policy_preset():
		"martial": return "arena"
		"artist", "leader": return "library"
		"explorer", "care": return "forest"
		_: return "academy"


func _reserve_gold_number() -> float:
	return _big_to_number(_read(["growthPolicy", "reserveGold"], {"mantissa": 3.0, "exponent": 2}))


func _career_title_count() -> int:
	var titles = _read(["careerTitles"], {})
	return titles.size() if typeof(titles) == TYPE_DICTIONARY else 0


func _career_display_name(title_id: String, title_data: Variant) -> String:
	if title_data is not Dictionary:
		return title_id
	var variant_name := str((title_data as Dictionary).get("variantName", "")).strip_edges()
	if not variant_name.is_empty():
		return variant_name
	return str((title_data as Dictionary).get("name", title_id))


func _career_rank(stars: int) -> String:
	return "명인 +%d" % (stars - 5) if stars > 5 else "%d성" % max(1, stars)


func _event_inbox() -> Array:
	var events = _read(["eventInbox"], [])
	return events.duplicate(true) if typeof(events) == TYPE_ARRAY else []


func _event_display_name(event_id: String) -> String:
	for raw_event in _events:
		if typeof(raw_event) == TYPE_DICTIONARY and str(raw_event.get("id", "")) == event_id:
			return str(raw_event.get("title", raw_event.get("name", event_id)))
	return event_id


func _event_choice_display_name(event_id: String, choice_id: String) -> String:
	for raw_event in _events:
		if typeof(raw_event) != TYPE_DICTIONARY or str(raw_event.get("id", "")) != event_id:
			continue
		for raw_choice in raw_event.get("choices", []):
			if typeof(raw_choice) == TYPE_DICTIONARY and str(raw_choice.get("id", "")) == choice_id:
				return str(raw_choice.get("text", choice_id))
	return "선택 기록 없음" if choice_id.is_empty() or choice_id == "-" else choice_id


func _item_display_name(item_id: String) -> String:
	var item := _item_by_id(item_id)
	return str(item.get("name", item_id.replace("_", " ")))


func _item_by_id(item_id: String) -> Dictionary:
	for raw_item in _items:
		if typeof(raw_item) == TYPE_DICTIONARY and str(raw_item.get("id", "")) == item_id:
			return raw_item as Dictionary
	return {}


func _item_category_name(category: String) -> String:
	return {"outfit": "의상", "accessory": "장신구", "weapon": "무기", "armor": "방어구", "consumable": "소비품"}.get(category, category)


func _inventory_stack(item_id: String) -> Dictionary:
	for raw_stack in _read(["inventory"], []):
		if typeof(raw_stack) == TYPE_DICTIONARY and str(raw_stack.get("id", "")) == item_id:
			return raw_stack as Dictionary
	return {}


func _inventory_count_ui(item_id: String) -> int:
	return int(_inventory_stack(item_id).get("count", 0))


func _inventory_enhancement_level(item_id: String) -> int:
	return int(_inventory_stack(item_id).get("enhancementLevel", 0))


func _equipped_slot_for(item_id: String) -> String:
	var equipment: Dictionary = _read(["equipment"], {})
	for slot in equipment:
		if str(equipment[slot]) == item_id:
			return str(slot)
	return ""


func _equipment_visual_state() -> Dictionary:
	var result: Dictionary = (_read(["equipment"], {}) as Dictionary).duplicate(true)
	var levels: Dictionary = {}
	for slot_id in ["outfit", "weapon", "armor", "accessory"]:
		var item_id := str(result.get(slot_id, ""))
		if not item_id.is_empty():
			levels[slot_id] = maxi(1, _inventory_enhancement_level(item_id))
	result["enhancementLevels"] = levels
	result["visualSeed"] = int(_state.get("seed", 1))
	return result


func _tier_item_price_number(item: Dictionary) -> float:
	var tier_growth := maxf(1.0, _config_float("activityCostTierGrowth", 1.11))
	return maxf(0.0, float(item.get("basePrice", 0.0))) * pow(tier_growth, float(maxi(0, int(_state.get("worldTier", 1)) - 1)))


func _tier_item_price_text(item: Dictionary) -> String:
	var base_price := maxf(0.0, float(item.get("basePrice", 0.0)))
	if base_price <= 0.0:
		return "0"
	var tier_growth := maxf(1.0, _config_float("activityCostTierGrowth", 1.11))
	var log_value := log(base_price) / log(10.0) + float(maxi(0, int(_state.get("worldTier", 1)) - 1)) * log(tier_growth) / log(10.0)
	var exponent := int(floor(log_value))
	var mantissa := pow(10.0, log_value - float(exponent))
	return _format_big({"mantissa": mantissa, "exponent": exponent})


func _game_config() -> Dictionary:
	if _engine != null and _engine.has_method("get_content_db"):
		var content_db: Object = _engine.call("get_content_db") as Object
		if content_db != null:
			var live_config: Variant = content_db.get("config")
			if live_config is Dictionary:
				return live_config as Dictionary
	return _runtime_config


func _config_int(key: String, fallback: int) -> int:
	return int(_game_config().get(key, fallback))


func _config_float(key: String, fallback: float) -> float:
	return float(_game_config().get(key, fallback))


func _offline_cap_slots() -> int:
	var seconds_per_slot := maxi(1, _config_int("offlineSecondsPerSlot", 60))
	return maxi(0, _config_int("offlineCapSeconds", 28800) / seconds_per_slot)


func _duration_label(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	if seconds > 0 and seconds % 3600 == 0:
		return "%d시간" % (seconds / 3600)
	if seconds > 0 and seconds % 60 == 0:
		return "%d분" % (seconds / 60)
	return "%d초" % seconds


func _read(path: Array, fallback = null):
	var cursor = _state
	for key in path:
		if typeof(cursor) != TYPE_DICTIONARY or not cursor.has(key):
			return fallback
		cursor = cursor[key]
	return cursor


func _deep_merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in overlay:
		if result.has(key) and typeof(result[key]) == TYPE_DICTIONARY and typeof(overlay[key]) == TYPE_DICTIONARY:
			result[key] = _deep_merge(result[key], overlay[key])
		else:
			result[key] = overlay[key]
	return result


func _format_big(value) -> String:
	if typeof(value) == TYPE_DICTIONARY and int(value.get("exponent", 0)) > 15:
		return "%.2fe%d" % [float(value.get("mantissa", 0.0)), int(value.get("exponent", 0))]
	return _format_number(_big_to_number(value))


func _big_to_number(value) -> float:
	if typeof(value) == TYPE_DICTIONARY:
		var mantissa := float(value.get("mantissa", 0.0))
		var exponent := int(value.get("exponent", 0))
		if exponent > 15:
			return mantissa * pow(10.0, 15.0)
		return mantissa * pow(10.0, float(exponent))
	return float(value)


func _number_to_big(value: float) -> Dictionary:
	if value <= 0.0:
		return {"mantissa": 0.0, "exponent": 0}
	var exponent := int(floor(log(value) / log(10.0)))
	return {"mantissa": value / pow(10.0, float(exponent)), "exponent": exponent}


func _format_number(value: float) -> String:
	var absolute := absf(value)
	if absolute < 1000.0:
		return "%d" % int(round(value))
	if absolute < 1000000.0:
		return "%.1f천" % (value / 1000.0)
	if absolute < 100000000.0:
		return "%.1f만" % (value / 10000.0)
	if absolute < 1000000000000.0:
		return "%.1f억" % (value / 100000000.0)
	return "%.2e" % value


func _has_engine_method(method: String) -> bool:
	return _engine != null and _engine.has_method(method)


func _adopt_engine_result(result: Variant) -> void:
	if result is Dictionary:
		var result_dict: Dictionary = result as Dictionary
		if result_dict.get("state") is Dictionary:
			_state = _deep_merge(_engine_state_shape(), result_dict["state"] as Dictionary)
			return
		if result_dict.has("schemaVersion") and result_dict.get("stats") is Dictionary:
			_state = _deep_merge(_engine_state_shape(), result_dict)
			return
	_sync_engine_state()


func _persist_silently() -> bool:
	if _engine == null:
		return false
	var wall_now := _now_unix()
	var save_boundary := wall_now
	var preserve_last_simulated_at := false
	if int(_state.get("pendingOfflineSlots", 0)) > 0:
		save_boundary = int(_state.get("lastSimulatedAt", save_boundary))
		preserve_last_simulated_at = true
	elif int(_state.get("lastSimulatedAt", 0)) > wall_now:
		preserve_last_simulated_at = true
	if _engine.has_method("save_game"):
		return _result_ok(_engine.call("save_game", "", save_boundary, preserve_last_simulated_at))
	if _engine.has_method("save"):
		return _result_ok(_engine.call("save", "", save_boundary, preserve_last_simulated_at))
	if _engine.has_method("persist"):
		var result: Variant = _engine.call("persist")
		return _result_ok(result) if result != null else true
	return false


# 화면의 모든 시각 판단은 이 경계를 지난다. 테스트는 princess_tycoon/testing/fixed_unix로 시계를 고정한다.
func _now_unix() -> int:
	var fixed_unix := int(ProjectSettings.get_setting("princess_tycoon/testing/fixed_unix", 0))
	return fixed_unix if fixed_unix > 0 else int(Time.get_unix_time_from_system())


func _stamp_engine_time_boundary(now_unix: int = -1) -> void:
	if _engine == null or not _engine.has_method("advance_slots"):
		return
	var boundary := now_unix if now_unix >= 0 else _now_unix()
	_adopt_engine_result(_engine.call("advance_slots", 0, boundary))


func _pending_offline_slots() -> int:
	if not bool(_read(["settings", "autoRun"], true)):
		return 0
	var last_seen := int(_state.get("lastSimulatedAt", 0))
	if last_seen <= 0:
		return 0
	var now := _now_unix()
	if now <= last_seen:
		return 0
	var seconds_per_slot := maxi(1, _config_int("offlineSecondsPerSlot", 60))
	return clampi((now - last_seen) / seconds_per_slot, 0, _offline_cap_slots())


func _initialize_runtime_ports() -> void:
	_analytics_port = LocalAnalyticsPort.new()
	_ad_port = NoOpAdPort.new()
	_iap_port = NoOpIapPort.new()
	_audio_port = SynthAudioPort.new()
	_audio_port.name = "RuntimeAudioPort"
	add_child(_audio_port)
	_audio_port.call("set_enabled", bool(_read(["settings", "sound"], true)))
	_audio_port.call("play_bgm", SynthAudioPort.SILENT_BGM)
	_track_event(&"session_started", {
		"worldTier": int(_state.get("worldTier", 1)),
		"preset": _policy_preset(),
	})


func _track_event(event_name: StringName, parameters: Dictionary = {}) -> void:
	if _analytics_port != null and _analytics_port.has_method("track"):
		_analytics_port.call("track", event_name, parameters)


func _play_sfx(cue: StringName) -> void:
	if _audio_port != null and _audio_port.has_method("play_cue"):
		_audio_port.call("play_cue", cue)


func _on_button_pressed(label_text: String) -> void:
	_play_sfx(SynthAudioPort.CUE_BUTTON)
	_track_event(&"button_pressed", {"screen": _current_tab, "label": label_text})


func _result_ok(result: Variant) -> bool:
	if result is Dictionary:
		return bool((result as Dictionary).get("ok", true))
	return result != null and result != false
