extends SceneTree

const SAVE_PATH := "user://qa_ui_motion_smoke_save.json"

var _failures: Array[String] = []
var _passes := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[UI-MOTION] Result feedback and reduced motion")
	_prepare_test_save()
	root.size = Vector2i(390, 844)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main scene 로드")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	# 이 테스트는 결과 연출과 목록 동작을 본다. 단계적 해금과 무관하게 모든 단계를 연 상태에서 시작한다.
	var unlock_engine: Object = main.get("_engine") as Object
	if unlock_engine != null:
		var opened_state: Dictionary = unlock_engine.call("get_state") as Dictionary
		opened_state["unlocks"] = {"stage": 7, "announced": 7, "tipsSeen": []}
		main.call("_adopt_engine_result", unlock_engine.call("initialize_from_state", opened_state))
		main.call("_refresh_chrome")
		await process_frame

	# 토스트는 아래 버튼을 가리지만 입력을 막으면 안 된다(토스트 글자가 탭을 가로채던 회귀 방지).
	var toast_panel: Control = main.get("_toast_panel") as Control
	var toast_blocks := 0
	if toast_panel != null:
		for node: Node in [toast_panel] + toast_panel.find_children("*", "Control", true, false):
			if (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
				toast_blocks += 1
	_check(toast_panel != null and toast_blocks == 0, "토스트와 글자가 입력을 가로채지 않음")
	# 이유·잠금 문구는 내부 점수나 슬롯 용어 없이 보여 준다.
	_check(str(main.call("_reason_label_text", "성장 방향 +1.450")) == "성장 방향" and str(main.call("_reason_label_text", "위험 부담 -0.039")) == "위험 부담", "다음 선택 이유에서 내부 점수 제거")
	var reason_stats: Dictionary = (main.get("_state") as Dictionary).get("stats", {}) as Dictionary
	var saved_intelligence: Variant = reason_stats.get("intelligence", 0.0)
	reason_stats["intelligence"] = 10.0
	var magic_requirement := str(main.call("_activity_requirement_reason", "EDU_MAGIC"))
	_check(str(main.call("_friendly_rejection", "예정 도전 우선: 4번 슬롯", "")) == "시즌 4일째 시험과 겹쳐요" and magic_requirement.begins_with("지력 60") and str(main.call("_friendly_rejection", "잠금 조건 미충족", "EDU_MAGIC")) == magic_requirement and str(main.call("_friendly_rejection", "잠금 조건 미충족", "")) == "조건을 채우면 열려요", "잠금 이유를 플레이어 문구로 변환")
	reason_stats["intelligence"] = saved_intelligence
	_check(str(main.call("_josa", "응용 마력학", "을", "를")) == "응용 마력학을" and str(main.call("_josa", "달빛 잎차", "을", "를")) == "달빛 잎차를", "받침에 맞는 조사 선택")
	var lock_state: Dictionary = main.get("_state") as Dictionary
	var saved_task: Variant = lock_state.get("activeTask")
	lock_state["activeTask"] = {"activityId": "CH_EXAM_ACADEMY", "remainingSlots": 1}
	_check(str(main.call("_activity_lock_reason", "CH_EXAM_ACADEMY")) == "진행 중 · 1일 남음", "진행 중인 시험은 다시 참가할 수 없음")
	lock_state["activeTask"] = saved_task
	# 자동 진행으로 끝난 평범한 근무는 띠, 업무 사고는 결과 창(사고 배지)으로 보여 준다.
	var calm_job := {"completedActivities": [{"activityId": "JOB_FARM", "kind": "job", "title": "학당 농장 완료", "gains": {"stamina": 3.0}, "outcome": {"event": "평온한 근무", "incident": false}}]}
	main.call("_present_result_feedback", calm_job, {}, true)
	await process_frame
	var feedback_layer: Variant = main.get("_result_feedback_layer")
	_check(str(feedback_layer.call("active_motion_mode")) == "compact", "자동 진행의 평온한 근무 결과는 하단 띠")
	var incident_job := {"completedActivities": [{"activityId": "JOB_FARM", "kind": "job", "title": "학당 농장 완료", "gains": {"stamina": 3.0}, "outcome": {"event": "도구 파손", "incident": true, "stressGain": 6.0}}]}
	main.call("_present_result_feedback", incident_job, {}, true)
	await process_frame
	var incident_payload: Dictionary = (feedback_layer.get("_active_panel") as Control).get_meta("payload", {}) as Dictionary
	_check(str(feedback_layer.call("active_motion_mode")) != "compact" and str(incident_payload.get("badge", "")) == "사고", "업무 사고는 사고 배지 결과 창")
	feedback_layer.call("_clear_active")
	# 목록이 움직이는 동안에는 자동 진행의 화면 갱신을 미룬다.
	main.call("_show_tab", "activity")
	for frame_index in 12:
		await process_frame
	var activity_scroll: ScrollContainer = null
	for child in (main.get("_content_host") as Node).get_children():
		if child is ScrollContainer and not child.is_queued_for_deletion():
			activity_scroll = child as ScrollContainer
	activity_scroll.scroll_vertical = 120
	await process_frame
	_check(bool(main.call("_list_in_motion")), "목록이 움직이는 중이면 갱신을 미룸")
	for frame_index in 10:
		await process_frame
	_check(not bool(main.call("_list_in_motion")), "목록이 멈추면 갱신 재개")
	main.call("_show_tab", "home")
	await process_frame
	var avatar_now: Variant = main.get("_home_avatar")
	for frame_index in 30:
		await process_frame
	_check(avatar_now != null and float(avatar_now.get("progress")) > 0.0, "홈 말풍선 진행 게이지가 자동 진행을 따라감")
	var layer: Variant = main.get("_result_feedback_layer")
	_check(layer != null and layer.has_method("present"), "결과 피드백 단일 레이어 연결")
	var activity_progress: Variant = main.get("_activity_progress")
	_check(activity_progress != null and activity_progress.get_script() != null and activity_progress.custom_minimum_size.x >= 44.0, "현재 활동 원형 진행 피드백 연결")
	var initialized_state: Dictionary = main.get("_state") as Dictionary
	_check(int(initialized_state.get("lastSimulatedAt", 0)) > 0, "새 세션 시간 경계를 저장해 오프라인 진행 기준점 확보")
	_check(str(main.call("_event_choice_display_name", "EV_NEW_YEAR", "plan")) == "구체적인 훈련 목표를 적는다", "이벤트 도감 마지막 선택 ID를 한국어 선택문으로 표시")
	var original_policy: Dictionary = (initialized_state.get("growthPolicy", {}) as Dictionary).duplicate(true)
	var policy_label := Label.new()
	var percent_formatter := func(raw_value: Variant) -> String: return "%d%%" % int(round(float(raw_value)))
	main.call("_on_policy_slider_changed", 50.0, "weight:stamina", policy_label, percent_formatter)
	var normalized_weights: Dictionary = (main.get("_state") as Dictionary).get("growthPolicy", {}).get("weights", {}) as Dictionary
	var normalized_total := 0.0
	for raw_weight: Variant in normalized_weights.values():
		normalized_total += float(raw_weight)
	_check(is_equal_approx(float(normalized_weights.get("stamina", 0.0)), 0.5) and absf(normalized_total - 1.0) < 0.0001 and policy_label.text == "50%", "직접 설계 slider 선택 비율·전체 정규화·label 정합")
	policy_label.free()
	main.call("_apply_policy", original_policy)
	initialized_state = main.get("_state") as Dictionary
	var original_task: Variant = initialized_state.get("activeTask")
	initialized_state["activeTask"] = {"activityId": "JOB_FARM"}
	var job_environment := str(main.call("_profile_environment"))
	initialized_state["activeTask"] = {"activityId": "ADV_FOREST"}
	var adventure_environment := str(main.call("_profile_environment"))
	initialized_state["activeTask"] = {"activityId": "CH_SPORT_DANCE"}
	var challenge_environment := str(main.call("_profile_environment"))
	initialized_state["activeTask"] = original_task
	_check(job_environment == "city" and adventure_environment == "forest" and challenge_environment == "arena", "활동 종류가 거리·숲·경기장 절차 배경에 연결")
	if layer == null:
		main.queue_free()
		_finish()
		return
	main.call("_open_sheet", "settings")
	await process_frame
	main.call("_close_sheet")
	await process_frame
	_check(is_instance_valid(layer) and layer.get_parent() != null, "시트 열기·닫기 뒤 결과 피드백 영구 레이어 보존")

	var activity_result := {
		"activityId": "EDU_LITERATURE",
		"kind": "education",
		"title": "왕립 교양학 완료",
		"gains": {"intelligence": 8.4, "communication": 4.1},
		"reward": {"mantissa": 2.5, "exponent": 2},
		"mastery": 7,
		"outcome": {"reputationGain": 2.0, "relationGain": 1.0},
	}
	var activity_payload: Dictionary = main.call("_build_result_feedback_payload", activity_result, {})
	_check(str(activity_payload.get("kind", "")) == "activity", "활동 결과 payload 분류")
	# 능력치는 칩으로, 보상은 상세 줄로 보인다(칩이 모든 성장을 보여 주면 같은 성장 줄은 반복하지 않는다).
	var shown_text := _joined_details(activity_payload) + " " + " ".join(activity_payload.get("floatingStats", []))
	# 칩(최대 3개)이 못 보여 주는 네 번째 이후 성장은 성장 줄로 남아야 한다.
	var wide_payload: Dictionary = main.call("_build_result_feedback_payload", {"activityId": "EDU_LITERATURE", "kind": "education", "title": "왕립 교양학 완료", "gains": {"intelligence": 8.4, "communication": 4.1, "refinement": 2.0, "art": 1.2}}, {})
	_check(_joined_details(wide_payload).contains("예술 +1.2"), "네 번째 이후 성장도 결과 창에 표시")
	var before_events := {"worldTier": 1, "titles": 0, "stats": 100.0, "gold": 50.0, "events": 2}
	var after_events := {"worldTier": 1, "titles": 0, "stats": 100.0, "gold": 50.0, "events": 5}
	_check((main.call("_progress_changes", before_events, after_events) as Array).has("처리한 이벤트 3건"), "정산 이벤트는 처리 횟수로 셈")
	_check(shown_text.contains("지력 +8.4") and shown_text.contains("골드 +250"), "실제 스탯·보상 결과 표시")
	_check((activity_payload.get("floatingStats", []) as Array).size() == 2, "능력치별 플로팅 토큰 생성")
	layer.call("present", activity_payload, false)
	await process_frame
	_check(layer.call("active_feedback_kind") == "activity" and layer.call("active_motion_mode") == "animated", "기본 활동 카드 Tween 연출")
	_check(int(layer.call("active_floating_stat_count")) == 2, "능력치 플로팅 칩을 개별 시각 요소로 표시")
	var active_feedback_panel: Control = layer.get("_active_panel") as Control
	if active_feedback_panel != null and active_feedback_panel.size.y > 240.0:
		print("[UI-MOTION] feedback panel diagnostic size=%s min=%s pos=%s anchors=%s/%s offsets=%s/%s parent=%s" % [str(active_feedback_panel.size), str(active_feedback_panel.get_combined_minimum_size()), str(active_feedback_panel.position), str(active_feedback_panel.anchor_top), str(active_feedback_panel.anchor_bottom), str(active_feedback_panel.offset_top), str(active_feedback_panel.offset_bottom), str((active_feedback_panel.get_parent() as Control).size)])
		for raw_feedback_node: Node in active_feedback_panel.find_children("*", "Control", true, false):
			var feedback_control := raw_feedback_node as Control
			print("[UI-MOTION] feedback child %s/%s size=%s min=%s" % [feedback_control.get_class(), feedback_control.name, str(feedback_control.size), str(feedback_control.get_combined_minimum_size())])
	_check(active_feedback_panel != null and active_feedback_panel.size.y <= 240.0, "결과 카드가 모바일 상단 영역 높이 안에 유지 size=%s" % str(active_feedback_panel.size if active_feedback_panel != null else Vector2.ZERO))
	_check(int(layer.call("active_detail_count")) <= 4, "모바일 결과 카드 상세 4줄 상한")
	layer.call("present", activity_payload, true)
	await process_frame

	var challenge_result := {
		"activityId": "CH_EXAM_ACADEMY",
		"kind": "challenge",
		"title": "아카데미 종합시험 완료",
		"gains": {"intelligence": 3.2},
		"reward": {"mantissa": 0.0, "exponent": 0},
		"outcome": {
			"won": false,
			"playerScore": 91.2,
			"opponentScore": 104.7,
			"rank": "participation",
			"leagueTier": 2,
			"nextLeagueTier": 1,
			"rivalName": "새벽 기록관 루나",
			"hint": "지력 유효 점수를 약 12.0 보강하세요.",
			"rewardGold": {"mantissa": 1.2, "exponent": 2},
		},
	}
	var challenge_payload: Dictionary = main.call("_build_result_feedback_payload", challenge_result, {})
	_check(str(challenge_payload.get("kind", "")) == "challenge" and str(challenge_payload.get("headline", "")).contains("도전 경험"), "도전 실패 강조 분류")
	_check(_joined_details(challenge_payload).contains("91.2") and _joined_details(challenge_payload).contains("104.7") and _joined_details(challenge_payload).contains("지력 유효 점수"), "도전 점수·상대·개선 hint 표시")
	var challenge_persistent: Array = main.call("_result_specialized_summary_lines", challenge_result)
	_check("\n".join(challenge_persistent).contains("참가") and "\n".join(challenge_persistent).contains("다음 준비") and not "\n".join(challenge_persistent).contains("participation"), "홈 최근 결과 도전 등급 한국어 상세 유지")

	var job_result := {
		"activityId": "JOB_RANGER",
		"kind": "job",
		"title": "외곽 경비 완료",
		"gains": {"stamina": 4.1},
		"reward": {"mantissa": 2.1, "exponent": 2},
		"outcome": {
			"type": "job", "incident": true, "event": "작업 중 돌발 사고",
			"rewardMultiplier": 0.68, "effects": {"stress": 8.2, "citizens": -1.9},
		},
	}
	var job_payload: Dictionary = main.call("_build_result_feedback_payload", job_result, {})
	var job_details := _joined_details(job_payload)
	_check(job_details.contains("돌발 사고") and job_details.contains("스트레스 +8.2") and job_details.contains("보수 68%"), "아르바이트 위험 사건 결과 표시")

	var adventure_result := {
		"activityId": "ADV_FOREST",
		"kind": "adventure",
		"title": "별빛 숲 원정 완료",
		"gains": {"combat": 2.4},
		"reward": {"mantissa": 0.0, "exponent": 0},
		"outcome": {
			"won": false,
			"clearedNodes": 2,
			"nodes": [
				{"type": "exploration", "event": "지도 조각 발견"},
			{"type": "encounter", "event": "적 조우", "enemyName": "안개빛 수호체", "enemyTraitName": "민첩"},
			{"type": "boss", "event": "지역 보스", "enemyName": "봉인된 골렘", "enemyTraitName": "견고"},
			],
			"loot": [{"itemId": "ITEM_TEA", "count": 2}],
			"injured": true,
			"regionName": "안개 낀 별빛 숲",
			"regionReward": {"mantissa": 3.5, "exponent": 2},
			"rewardFragment": "희귀 연구 표본",
		},
	}
	var adventure_payload: Dictionary = main.call("_build_result_feedback_payload", adventure_result, {})
	var adventure_details := _joined_details(adventure_payload)
	_check(str(adventure_payload.get("badge", "")) == "원정" and adventure_details.contains("탐색") and adventure_details.contains("조우") and adventure_details.contains("보스"), "모험 3노드 결과 표시")
	_check(adventure_details.contains("안개빛 수호체") and adventure_details.contains("민첩") and adventure_details.contains("봉인된 골렘") and adventure_details.contains("견고"), "생성 적 이름·특성을 모험 결과에 표시")
	_check(adventure_details.contains("전리품") and adventure_details.contains("지역 보상") and adventure_details.contains("희귀 연구 표본") and adventure_details.contains("강제 휴식"), "모험 loot·regionReward·보상 조각·부상 후 휴식 표시")

	var title_review := {
		"year": 2,
		"season": 3,
		"renownGained": 78,
		"policyFit": 0.84,
		"worldTierBefore": 3,
		"worldTierAfter": 4,
		"titles": [{"id": "END_SCHOLAR", "name": "왕립 연구자", "stars": 2, "rank": "2성"}],
	}
	var title_payload: Dictionary = main.call("_build_result_feedback_payload", {}, title_review)
	_check(str(title_payload.get("kind", "")) == "title" and str(title_payload.get("headline", "")).contains("별 상승"), "진로 칭호 별 상승 연출 훅")
	_check(_joined_details(title_payload).contains("왕립 연구자") and _joined_details(title_payload).contains("3 > 4"), "칭호·세계 티어 실제 심사 데이터 표시")
	_check(
		str(main.call("_career_display_name", "END_SCHOLAR", {"name": "왕립 연구자", "variantName": "시민의 왕립 연구자"})) == "시민의 왕립 연구자",
		"관계 기반 진로 칭호 변형을 기록 화면에 지속 표시"
	)

	layer.call("present", title_payload, false)
	await process_frame
	main.call("_toggle_setting", true, "reducedMotion")
	await process_frame
	_check(layer.call("active_motion_mode") == "static", "실행 중 Tween을 reducedMotion으로 즉시 정지")
	var home_avatar: Variant = main.get("_home_avatar")
	_check(home_avatar != null and bool(home_avatar.get("reduced_motion")), "현재 홈 캐릭터도 reducedMotion을 즉시 반영")
	layer.call("present", challenge_payload, true)
	await process_frame
	_check(layer.call("active_motion_mode") == "static", "reducedMotion 신규 결과는 정적 카드 대체")
	var full_panel: Control = layer.get("_active_panel") as Control
	_check(full_panel != null and full_panel.mouse_filter == Control.MOUSE_FILTER_STOP, "결과 창은 탭을 받아 아래 버튼으로 새지 않음")
	# 결과 창이 떠 있으면 한 줄 띠를 띄우지 않으므로, 창을 닫은 뒤 자동 결과를 띄운다.
	layer.call("_clear_active")
	layer.call("present", challenge_payload, false, true)
	await process_frame
	var banner: Control = layer.get("_active_panel") as Control
	_check(layer.call("active_motion_mode") == "compact" and banner != null and banner.mouse_filter == Control.MOUSE_FILTER_IGNORE and banner.anchor_top == 1.0 and banner.get_rect().size.y <= 60.0, "자동 진행 결과는 하단 한 줄 띠로 장면을 가리지 않음")

	# 결과 창에 실제로 보이는 줄(상세 4줄 상한) 안에 나머지 성장과 보상이 빠지지 않는다(이슈 #9).
	var five_gains := {"intelligence": 6.0, "communication": 4.0, "refinement": 3.0, "art": 2.0, "etiquette": 1.5}
	var won_challenge: Dictionary = challenge_result.duplicate(true)
	won_challenge["gains"] = five_gains
	won_challenge["reward"] = {"mantissa": 3.0, "exponent": 2}
	var won_outcome: Dictionary = won_challenge["outcome"] as Dictionary
	won_outcome["won"] = true
	won_outcome["rank"] = "honors"
	won_outcome["nextLeagueTier"] = 3
	won_outcome["hint"] = "현재 구성으로 다음 리그를 준비할 수 있습니다."
	won_outcome["rewardGold"] = {"mantissa": 3.0, "exponent": 2}
	var won_lines := await _shown_lines(layer, main.call("_build_result_feedback_payload", won_challenge, {}) as Dictionary)
	_check(won_lines.contains("그 외 성장") and won_lines.count("골드 +300") == 1 and not won_lines.contains("현재 구성으로"), "도전 승리 결과 창에 나머지 성장과 보상 한 번 [%s]" % won_lines.replace("\n", " / "))
	var lost_challenge: Dictionary = challenge_result.duplicate(true)
	lost_challenge["gains"] = five_gains
	var lost_lines := await _shown_lines(layer, main.call("_build_result_feedback_payload", lost_challenge, {}) as Dictionary)
	_check(lost_lines.contains("다음 준비") and lost_lines.contains("그 외 성장"), "도전 실패 결과 창에 조언과 나머지 성장 [%s]" % lost_lines.replace("\n", " / "))
	var plain_review := {"year": 1, "season": 1, "renownGained": 12, "policyFit": 0.7, "challengeWins": 0, "completedContracts": 0}
	var review_lines := await _shown_lines(layer, main.call("_build_result_feedback_payload", {"activityId": "EDU_LITERATURE", "kind": "education", "title": "왕립 교양학 완료", "gains": five_gains}, plain_review) as Dictionary)
	_check(review_lines.contains("그 외 성장") and review_lines.contains("심사 보상"), "심사 결과 창에 나머지 성장 [%s]" % review_lines.replace("\n", " / "))
	var many_titles: Dictionary = title_review.duplicate(true)
	many_titles["titles"] = [
		{"id": "END_SCHOLAR", "name": "왕립 연구자", "stars": 2, "rank": "2성"},
		{"id": "END_GUARD", "name": "검의 수호자", "stars": 1, "rank": "1성"},
		{"id": "END_C", "name": "별빛 화가", "stars": 1, "rank": "1성"},
		{"id": "END_D", "name": "도시의 목소리", "stars": 1, "rank": "1성"},
	]
	var title_lines := await _shown_lines(layer, main.call("_build_result_feedback_payload", {}, many_titles) as Dictionary)
	_check(title_lines.contains("외 2개") and title_lines.contains("심사 보상") and title_lines.contains("3 > 4"), "칭호가 많아도 심사 보상과 티어 줄 표시 [%s]" % title_lines.replace("\n", " / "))

	# 긴 결과 제목은 띄어쓰기에서만 줄을 바꾼다. 한글은 음절 사이에서도 줄을 바꿀 수 있어 "은 / 잎"처럼 낱말이 갈렸다(이슈 #9).
	var long_title := "원정 성공 · 미지로 향하는 은잎 숲"
	layer.call("present", {"kind": "challenge", "badge": "원정", "tone": "gold", "headline": long_title, "floatingStats": [], "details": []}, true)
	await process_frame
	await process_frame
	var headline_label: Label = null
	var long_panel := layer.get("_active_panel") as Control
	if long_panel != null:
		for raw_label: Node in long_panel.find_children("*", "Label", true, false):
			if (raw_label as Label).text.replace("\n", " ") == long_title:
				headline_label = raw_label as Label
	var explicit_lines := headline_label.text.split("\n").size() if headline_label != null else 0
	_check(headline_label != null and explicit_lines >= 2 and headline_label.get_line_count() == explicit_lines, "긴 결과 제목은 띄어쓰기에서만 줄바꿈 [%s]" % ("" if headline_label == null else headline_label.text.replace("\n", " / ")))

	# 한 번에 여러 단계가 열려도 새로 열림 줄이 잘리지 않는다. 대신 첫 상세 줄은 1줄로 줄여 창 높이를 지킨다.
	var multi_notice := "새로 열림 · 계획, 성장, 학습과 아르바이트 추가, 시험"
	layer.call("present", {"kind": "activity", "badge": "성장", "tone": "raised", "headline": "왕립 교양학 완료", "floatingStats": ["지력 +8.4"], "details": ["다음 준비 · 지력 유효 점수를 약 12.0 보강하면 다음 시험에서 이길 수 있어요.", "활동 보상 · 골드 +250"], "notice": multi_notice}, true)
	await process_frame
	await process_frame
	var multi_label: Label = null
	var hint_label: Label = null
	var multi_panel := layer.get("_active_panel") as Control
	if multi_panel != null:
		for raw_label: Node in multi_panel.find_children("*", "Label", true, false):
			if (raw_label as Label).text.replace("\n", " ") == multi_notice:
				multi_label = raw_label as Label
			elif (raw_label as Label).text.begins_with("다음 준비"):
				hint_label = raw_label as Label
	var multi_fits := multi_label != null and multi_label.get_line_count() == 2 and multi_label.get_visible_line_count() == 2
	_check(multi_fits and hint_label != null and hint_label.max_lines_visible == 1 and (multi_panel as Control).size.y <= 240.0, "여러 단계 새로 열림 줄은 잘리지 않고 창 높이 유지 [%s] h=%s" % ["" if multi_label == null else multi_label.text.replace("\n", " / "), str((multi_panel as Control).size.y if multi_panel != null else 0.0)])
	# 새로 열림이 한 줄이면 첫 상세 줄은 그대로 2줄까지 보인다.
	layer.call("present", {"kind": "activity", "badge": "성장", "tone": "raised", "headline": "왕립 교양학 완료", "floatingStats": ["지력 +8.4"], "details": ["다음 준비 · 지력 유효 점수를 약 12.0 보강하면 다음 시험에서 이길 수 있어요.", "활동 보상 · 골드 +250"], "notice": "새로 열림 · 기록, 계약"}, true)
	await process_frame
	await process_frame
	var single_hint: Label = null
	var single_panel := layer.get("_active_panel") as Control
	if single_panel != null:
		for raw_label: Node in single_panel.find_children("*", "Label", true, false):
			if (raw_label as Label).text.begins_with("다음 준비"):
				single_hint = raw_label as Label
	_check(single_hint != null and single_hint.max_lines_visible == 2 and single_hint.get_visible_line_count() == 2, "한 줄 새로 열림과 함께여도 첫 상세 줄은 2줄")

	# 결과 창이 떠 있는 동안 평범한 자동 결과(한 줄 띠)가 그 창을 지우지 않는다(직접 실행 직후 자동 진행이 돌 때).
	layer.call("present", {"kind": "activity", "badge": "성장", "tone": "raised", "headline": "왕립 교양학 완료", "floatingStats": ["지력 +8.4"], "details": [], "notice": "새로 열림 · 아르바이트 3종"}, true)
	await process_frame
	layer.call("present", {"kind": "activity", "headline": "기숙사 휴식 완료", "floatingStats": ["체력 +1.0"], "details": []}, true, true)
	await process_frame
	var kept_panel := layer.get("_active_panel") as Control
	var kept_notice := str((kept_panel.get_meta("payload", {}) as Dictionary).get("notice", "")) if kept_panel != null else ""
	_check(kept_notice == "새로 열림 · 아르바이트 3종" and str(layer.call("active_motion_mode")) != "compact", "결과 창이 떠 있으면 한 줄 자동 결과 띠가 창을 대신하지 않음")
	layer.call("_clear_active")

	# 결과 창과 함께 단계가 열리면 결과 창의 첫 줄로 알리고 알림 띠에는 넣지 않는다(이슈 #11).
	var notice_engine: Object = main.get("_engine") as Object
	var review_state: Dictionary = notice_engine.call("get_state") as Dictionary
	(review_state["time"] as Dictionary)["slot"] = 27
	(review_state["lifetimeStats"] as Dictionary)["activities"] = 30
	review_state["unlocks"] = {"stage": 4, "announced": 4, "tipsSeen": []}
	main.call("_adopt_engine_result", notice_engine.call("initialize_from_state", review_state))
	(main.get("_toast_label") as Label).text = ""
	main.call("_advance_slots", 1, true)
	await process_frame
	await process_frame
	var review_panel := layer.get("_active_panel") as Control
	var notice_line := ""
	if review_panel != null:
		for raw_label: Node in review_panel.find_children("*", "Label", true, false):
			if (raw_label as Label).text.begins_with("새로 열림 · "):
				notice_line = (raw_label as Label).text
	var toast_text := (main.get("_toast_label") as Label).text.replace("\n", " ")
	var review_unlocks: Dictionary = (main.get("_state") as Dictionary).get("unlocks", {}) as Dictionary
	_check(not notice_line.is_empty() and not toast_text.contains("새로 열림") and int(review_unlocks.get("announced", 0)) == 5, "심사로 열린 단계는 심사 결과 창 안에 [%s] 알림 띠 [%s]" % [notice_line, toast_text.replace("\n", " / ")])
	# 자동 진행 결과와 함께 열리면 한 줄 띠 대신 결과 창으로 보여 그 첫 줄에서 알린다(띠와 알림 띠가 겹치지 않게).
	var banner_state: Dictionary = notice_engine.call("get_state") as Dictionary
	(banner_state["time"] as Dictionary)["slot"] = 2
	(banner_state["lifetimeStats"] as Dictionary)["activities"] = 2
	banner_state["unlocks"] = {"stage": 1, "announced": 1, "tipsSeen": []}
	banner_state["seasonHistory"] = []
	banner_state["activityQueue"] = []
	banner_state["activeTask"] = {"activityId": "REST_WALK", "id": "REST_WALK", "durationSlots": 1, "remainingSlots": 1, "worldTier": 1, "paidCost": BigValue.zero()}
	main.call("_adopt_engine_result", notice_engine.call("initialize_from_state", banner_state))
	(main.get("_toast_label") as Label).text = ""
	main.call("_advance_slots", 1, false)
	await process_frame
	await process_frame
	var auto_notice := ""
	var auto_panel := layer.get("_active_panel") as Control
	if auto_panel != null:
		for raw_label: Node in auto_panel.find_children("*", "Label", true, false):
			if (raw_label as Label).text.begins_with("새로 열림 · "):
				auto_notice = (raw_label as Label).text
	var auto_toast := (main.get("_toast_label") as Label).text.replace("\n", " ")
	_check(int(((main.get("_state") as Dictionary).get("unlocks", {}) as Dictionary).get("announced", 0)) == 2 and str(layer.call("active_motion_mode")) != "compact" and not auto_notice.is_empty() and not auto_toast.contains("새로 열림"), "자동 진행 결과와 함께 열린 단계는 결과 창 첫 줄로 [%s] 띠 [%s]" % [auto_notice, auto_toast.replace("\n", " / ")])
	# 끝난 활동 없이(진행 중) 날짜로 열리면 결과가 없으므로 알림 띠로 알린다.
	layer.call("_clear_active")
	var day_state: Dictionary = notice_engine.call("get_state") as Dictionary
	(day_state["time"] as Dictionary)["slot"] = 13
	(day_state["lifetimeStats"] as Dictionary)["activities"] = 9
	day_state["unlocks"] = {"stage": 3, "announced": 3, "tipsSeen": []}
	day_state["activityQueue"] = []
	day_state["activeTask"] = {"activityId": "REST_HOME", "id": "REST_HOME", "durationSlots": 3, "remainingSlots": 3, "worldTier": 1, "paidCost": BigValue.zero()}
	main.call("_adopt_engine_result", notice_engine.call("initialize_from_state", day_state))
	main.call("_advance_slots", 1, false)
	await process_frame
	var day_toast := (main.get("_toast_label") as Label).text.replace("\n", " ")
	_check(int(((main.get("_state") as Dictionary).get("unlocks", {}) as Dictionary).get("announced", 0)) == 4 and day_toast.contains("새로 열림 · ") and not bool(layer.call("has_active_feedback")), "결과 없이 날짜로 열린 단계는 알림 띠로 [%s]" % day_toast.replace("\n", " / "))

	var trainee_script := load("res://src/ui/pixel/pixel_trainee_view.gd")
	var trainee: Control = trainee_script.new()
	trainee.size = Vector2(390, 388)
	trainee.call("set_reduced_motion", true)
	root.add_child(trainee)
	await process_frame
	var plain_image: Image = trainee.call("trainee_image")
	trainee.call("set_equipment", {
		"outfit": "OUTFIT_NOBLE",
		"weapon": "WPN_WAND",
		"armor": "ARM_ROBE",
		"accessory": "ACC_JEWEL",
		"enhancementLevels": {"outfit": 25, "weapon": 18, "armor": 12, "accessory": 8},
		"visualSeed": 1729,
	})
	await process_frame
	var equipped_image: Image = trainee.call("trainee_image")
	_check(int(trainee.call("_max_enhancement_level")) == 25, "장비 강화 레벨이 도트 외형 입력으로 연결")
	_check(plain_image != null and equipped_image != null and plain_image.get_data() != equipped_image.get_data(), "장착 장비가 페이퍼돌 레이어를 바꿈")
	trainee.call("set_profile", "martial")
	await process_frame
	var martial_image: Image = trainee.call("trainee_image")
	_check(martial_image.get_data() != equipped_image.get_data(), "성장 방향이 제복 색을 바꿈")
	for frame_index in 40:
		await process_frame
	_check(int(trainee.call("current_frame")) == 0, "모션 줄이기에서는 대기 프레임이 멈춤")
	trainee.queue_free()

	var engine: Variant = main.get("_engine")
	var live_config: Dictionary = engine.call("get_content_db").get("config") as Dictionary
	var original_offline_seconds := int(live_config.get("offlineSecondsPerSlot", 60))
	var original_offline_cap := int(live_config.get("offlineCapSeconds", 28800))
	live_config["offlineSecondsPerSlot"] = 30
	live_config["offlineCapSeconds"] = 90
	var config_state: Dictionary = main.get("_state") as Dictionary
	(config_state.get("settings", {}) as Dictionary)["autoRun"] = true
	config_state["lastSimulatedAt"] = int(Time.get_unix_time_from_system()) - 120
	_check(int(main.call("_offline_cap_slots")) == 3 and int(main.call("_pending_offline_slots")) == 3, "UI 오프라인 환산이 config 변경을 실제 behavior에 반영")
	live_config["offlineSecondsPerSlot"] = original_offline_seconds
	live_config["offlineCapSeconds"] = original_offline_cap
	var pending_state: Dictionary = engine.call("get_state") as Dictionary
	var pending_boundary := int(Time.get_unix_time_from_system()) - 3600
	pending_state["lastSimulatedAt"] = pending_boundary
	engine.call("initialize_from_state", pending_state)
	main.call("_sync_engine_state")
	var ui_state: Dictionary = main.get("_state") as Dictionary
	ui_state["pendingOfflineSlots"] = 60
	main.call("_persist_silently")
	var persisted_state: Dictionary = engine.call("get_state") as Dictionary
	_check(int(persisted_state.get("lastSimulatedAt", 0)) == pending_boundary, "오프라인 미정산 중 자동저장이 정산 기준시각을 보존")
	(ui_state.get("settings", {}) as Dictionary)["autoRun"] = false
	_check(int(main.call("_pending_offline_slots")) == 0, "자동 진행 일시정지는 오프라인 자동 성장도 중지")

	var paused_now := int(Time.get_unix_time_from_system())
	var paused_state := StateFactory.create(990001, "일시정지 만료")
	(paused_state.get("settings", {}) as Dictionary)["autoRun"] = false
	paused_state["lastSimulatedAt"] = paused_now - 120
	paused_state["eventInbox"] = [_expired_test_event("UI_PAUSED_EXPIRED", paused_now - 1)]
	engine.call("initialize_from_state", paused_state)
	main.call("_sync_engine_state")
	main.call("_notification", NOTIFICATION_APPLICATION_RESUMED)
	var paused_resumed: Dictionary = main.get("_state") as Dictionary
	_check((paused_resumed.get("eventInbox", []) as Array).is_empty() and (paused_resumed.get("eventHistory", {}) as Dictionary).has("UI_PAUSED_EXPIRED") and int((paused_resumed.get("time", {}) as Dictionary).get("slot", -1)) == 0, "일시정지 resume도 0-slot 이벤트 만료 정산")

	var wall_now := int(Time.get_unix_time_from_system())
	var future_boundary := wall_now + 3600
	var rollback_state: Dictionary = engine.call("get_state") as Dictionary
	rollback_state["lastSimulatedAt"] = future_boundary
	(rollback_state.get("settings", {}) as Dictionary)["autoRun"] = true
	engine.call("initialize_from_state", rollback_state)
	main.call("_adopt_engine_result", engine.call("settle_offline", wall_now))
	var rollback_ui_state: Dictionary = main.get("_state") as Dictionary
	rollback_ui_state["pendingOfflineSlots"] = 0
	var rollback_saved: bool = bool(main.call("_persist_silently"))
	var rollback_persisted: Dictionary = engine.call("get_state") as Dictionary
	var has_rollback_warning := false
	for raw_warning: Variant in rollback_persisted.get("warnings", []) as Array:
		if raw_warning is Dictionary and str((raw_warning as Dictionary).get("code", "")) == "CLOCK_ROLLBACK":
			has_rollback_warning = true
	_check(rollback_saved and int(rollback_persisted.get("lastSimulatedAt", 0)) == future_boundary and has_rollback_warning, "시계 역행 경고 저장이 미래 기준시각과 상태를 보존")

	var cold_now := int(Time.get_unix_time_from_system())
	var cold_state := StateFactory.create(990002, "냉시작 만료")
	(cold_state.get("settings", {}) as Dictionary)["autoRun"] = false
	cold_state["lastSimulatedAt"] = cold_now - 120
	cold_state["eventInbox"] = [_expired_test_event("UI_COLD_EXPIRED", cold_now - 1)]
	SaveCodec.save_atomic(SAVE_PATH, cold_state)
	main.queue_free()
	await process_frame
	var cold_main := packed.instantiate() as Control
	root.add_child(cold_main)
	await process_frame
	await process_frame
	var cold_loaded: Dictionary = cold_main.get("_state") as Dictionary
	_check((cold_loaded.get("eventInbox", []) as Array).is_empty() and (cold_loaded.get("eventHistory", {}) as Dictionary).has("UI_COLD_EXPIRED") and int((cold_loaded.get("time", {}) as Dictionary).get("slot", -1)) == 0, "일시정지 cold startup도 0-slot 이벤트 만료 정산")
	cold_main.queue_free()
	await process_frame
	_finish()


# 결과 창을 실제로 띄워 보이는 글자를 모은다(상세 줄 상한과 말줄임이 적용된 뒤).
func _shown_lines(layer: Control, payload: Dictionary) -> String:
	layer.call("present", payload, true)
	await process_frame
	await process_frame
	var lines: Array[String] = []
	var panel := layer.get("_active_panel") as Control
	if panel != null:
		for raw_label: Node in panel.find_children("*", "Label", true, false):
			lines.append((raw_label as Label).text)
	return "\n".join(lines)


func _joined_details(payload: Dictionary) -> String:
	var lines: Array[String] = []
	for raw_line: Variant in payload.get("details", []) as Array:
		lines.append(str(raw_line))
	return "\n".join(lines)


func _expired_test_event(event_id: String, expires_at: int) -> Dictionary:
	return {
		"id": event_id,
		"instanceId": "%s_INSTANCE" % event_id,
		"name": "만료 테스트",
		"queuedAtUnix": expires_at - 60,
		"expiresAtUnix": expires_at,
		"defaultChoice": "safe",
		"choices": [{"id": "safe", "text": "안전한 선택", "effects": {"stats": {"intelligence": 1.0}}}],
	}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print("[PASS] %s" % label)
	else:
		_failures.append(label)
		print("[FAIL] %s" % label)


func _finish() -> void:
	_cleanup_test_save()
	if _failures.is_empty():
		print("[UI-MOTION] PASS checks=%d" % _passes)
		quit(0)
		return
	print("[UI-MOTION] FAIL passed=%d failed=%d" % [_passes, _failures.size()])
	quit(1)


func _prepare_test_save() -> void:
	_cleanup_test_save()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE_PATH)


func _cleanup_test_save() -> void:
	var absolute := ProjectSettings.globalize_path(SAVE_PATH)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(absolute + suffix):
			DirAccess.remove_absolute(absolute + suffix)
