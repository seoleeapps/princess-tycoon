extends PanelContainer

signal closed
signal pause_toggled
signal expanded
const AdventureTheme = preload("res://src/ui/adventure_theme.gd")
const Juice = preload("res://addons/seorilabs_game/ui_kit/juice.gd")
const UiSfx = preload("res://addons/seorilabs_game/ui_kit/ui_sfx.gd")
const RewardCeremony = preload("res://addons/seorilabs_game/ui_kit/reward_ceremony.tscn")
const CurrencyChip = preload("res://addons/seorilabs_game/ui_kit/currency_chip.tscn")
const Stage = preload("res://src/ui/adventure_stage.gd")
const PixelTheme = preload("res://src/ui/pixel/pixel_theme.gd")
const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
var playback: RefCounted
var result: Dictionary = {}
var actor: Dictionary = {}
var compact := false
var reduced_motion := false
var sound_enabled := true
var paused := false
var _pause: Button
var _ceremony: Control
var _sfx: Node
var _loot_chip: Control
var _celebrated := false
var _was_still := false
var _stage: Control
var _event: Label
var _player_hp: Label
var _enemy_hp: Label
var _player_bar: ProgressBar
var _enemy_bar: ProgressBar
var _variant: Label
var _nodes: Label
var _rewards: Label
var _skip: Button
var _phase_key := ""

func _ready() -> void:
	theme = AdventureTheme.build()
	Juice.reduced_motion = reduced_motion or paused
	set_meta("ui_id", "adventure_scene")
	mouse_filter = Control.MOUSE_FILTER_IGNORE if compact else Control.MOUSE_FILTER_STOP
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE if compact else Control.MOUSE_FILTER_STOP
	layout.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	var outcome: Dictionary = result.get("outcome", {})
	var title := str(outcome.get("regionName", result.get("title", "탐험")))
	column.add_child(_label(("최근 원정 · " if compact else "") + title, 16 if compact else 24))
	_nodes = _label("탐색  ·  조우  ·  수호자", 16)
	column.add_child(_nodes)
	_variant = _label("", 16)
	_variant.visible = not compact
	column.add_child(_variant)
	_stage = Stage.new()
	_stage.playback = playback
	_stage.outcome = outcome
	_stage.profile = str(actor.get("profile", "balanced"))
	var raw_equipment: Variant = actor.get("equipment", {})
	_stage.equipment = raw_equipment if raw_equipment is Dictionary else {}
	_stage.reduced_motion = reduced_motion
	_stage.custom_minimum_size.y = 260.0 if compact else 340.0
	_stage.size_flags_vertical = Control.SIZE_FILL
	column.add_child(_stage)
	var hp_row := HBoxContainer.new()
	_player_hp = _label("", 16)
	_player_hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_hp = _label("", 16)
	_enemy_hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var player_column := VBoxContainer.new()
	player_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var enemy_column := VBoxContainer.new()
	enemy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_bar = _hp_bar("energy")
	_enemy_bar = _hp_bar("stress")
	player_column.add_child(_player_hp)
	player_column.add_child(_player_bar)
	enemy_column.add_child(_enemy_hp)
	enemy_column.add_child(_enemy_bar)
	hp_row.add_child(player_column)
	hp_row.add_child(enemy_column)
	column.add_child(hp_row)
	_event = _label("숲길을 살피고 있어요", 16)
	_event.custom_minimum_size.y = 42.0
	_event.set_meta("ui_id", "adventure_event")
	column.add_child(_event)
	_loot_chip = CurrencyChip.instantiate()
	_loot_chip.show_add = false
	_loot_chip.visible = not compact
	column.add_child(_loot_chip)
	_loot_chip.set_icon(load("res://assets/pixel/icons/coin.png"))
	_loot_chip.set_text("탐험 중")
	var chip_value := _loot_chip.get_node("Row/Value") as Label
	chip_value.add_theme_color_override("font_color", PixelTokens.INK)
	chip_value.add_theme_constant_override("outline_size", 0)
	_rewards = _label("", 16)
	_rewards.visible = not compact
	_rewards.custom_minimum_size.y = 64.0
	_rewards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rewards.set_meta("ui_id", "adventure_rewards")
	column.add_child(_rewards)
	var buttons := HBoxContainer.new()
	if not compact:
		_skip = _button("결과 보기", func() -> void: playback.call("skip"))
		_skip.set_meta("ui_id", "adventure_skip")
		buttons.add_child(_skip)
	else:
		var expand := _button("크게 보기", func() -> void: expanded.emit())
		expand.set_meta("ui_id", "adventure_expand")
		buttons.add_child(expand)
	_pause = _button("재생" if paused else "일시정지", func() -> void: pause_toggled.emit())
	_pause.set_meta("ui_id", "adventure_pause")
	buttons.add_child(_pause)
	if not compact:
		var close := _button("닫기", func() -> void: closed.emit())
		close.set_meta("ui_id", "adventure_close")
		buttons.add_child(close)
	layout.add_child(buttons)
	_sfx = UiSfx.attach(self)
	_sfx.enabled = sound_enabled and AudioServer.get_driver_name() != "Dummy"
	_ceremony = RewardCeremony.instantiate()
	_ceremony.sfx = _sfx
	add_child(_ceremony)
	if reduced_motion:
		playback.call("skip")

func _process(_delta: float) -> void:
	if playback == null or not is_visible_in_tree():
		return
	if _pause != null:
		_pause.text = "재생" if paused else "일시정지"
	_stage.reduced_motion = reduced_motion
	Juice.reduced_motion = reduced_motion or paused
	_sfx.enabled = sound_enabled and AudioServer.get_driver_name() != "Dummy"
	if (paused or reduced_motion) and not _was_still:
		_ceremony.skip()
		_ceremony.visible = false
		for child in _stage.get_children():
			if child.has_meta("motion_effect"):
				child.queue_free()
	_was_still = paused or reduced_motion
	var phase: Dictionary = playback.call("current")
	var key := JSON.stringify(phase)
	if _phase_key == key:
		return
	_phase_key = key
	var raw_trace: Variant = (result.get("outcome", {}) as Dictionary).get("presentation", {})
	var trace: Dictionary = raw_trace if raw_trace is Dictionary else {}
	var raw_max_hp: Variant = trace.get("maxPlayerHp", 0.0)
	var max_hp := float(raw_max_hp) if (raw_max_hp is int or raw_max_hp is float) and is_finite(float(raw_max_hp)) else 0.0
	_player_hp.text = "나 HP %d / %d" % [int(phase.get("playerHp", phase.get("remainingHp", max_hp))), int(max_hp)] if max_hp > 0 else ("남은 HP %d · 이전 기록" % int(phase["remainingHp"]) if phase.has("remainingHp") else "이전 탐험 기록")
	_enemy_hp.text = "상대 HP %d / %d" % [int(phase.get("enemyHp", 0)), int(phase.get("enemyMaxHp", 0))] if phase.has("enemyMaxHp") and phase.has("enemyHp") else ""
	_player_bar.visible = max_hp > 0
	_player_bar.max_value = maxf(1.0, max_hp)
	_player_bar.value = float(phase.get("playerHp", phase.get("remainingHp", max_hp)))
	_enemy_bar.visible = phase.has("enemyMaxHp") and phase.has("enemyHp")
	_enemy_bar.max_value = maxf(1.0, float(phase.get("enemyMaxHp", 1)))
	_enemy_bar.value = float(phase.get("enemyHp", 0))
	_nodes.text = "노드 %d / 3  ·  %s" % [clampi(int(phase.get("node", 1)), 1, 3), str(phase.get("enemyName", "탐험 경로"))]
	var variant_name := str(phase.get("variantName", ""))
	var trait_name := str(phase.get("enemyTraitName", ""))
	_variant.text = "지역 변형 · %s%s" % [variant_name, " · " + trait_name if not trait_name.is_empty() else ""] if not variant_name.is_empty() else ""
	_variant.visible = not compact and not _variant.text.is_empty()
	var type := str(phase.get("type", ""))
	if _skip != null:
		_skip.disabled = type == "result"
	if type != "result":
		_rewards.text = ""
		_loot_chip.set_text("탐험 중")
	var who := str(phase.get("actor", ""))
	if type == "result":
		_event.text = "탐험 완료" if bool((result.get("outcome", {}) as Dictionary).get("won", false)) else "후퇴했어요 · 회복 후 다시 도전하세요"
		_rewards.text = "\n".join(_reward_lines())
		_loot_chip.set_text(str(result.get("rewardChip", "원정 결과")))
		if not _celebrated:
			_celebrated = true
			if bool((result.get("outcome", {}) as Dictionary).get("won", false)) and not paused:
				_ceremony.present([{"icon": load("res://assets/pixel/icons/coin.png"), "label": str(result.get("rewardChip", "탐험 완료"))}], "탐험 완료", _loot_chip, null, 0, 0, Vector2(0.5, 0.48))
		if _skip != null:
			_skip.disabled = true
	elif who == "exchange":
		_event.text = "연속 공방 %d회 · 나 %d 피해 / 상대 %d 피해" % [int(phase.get("hitCount", 0)), int(phase.get("traineeDamage", 0)), int(phase.get("enemyDamage", 0))]
	elif who in ["trainee", "enemy"]:
		if not reduced_motion and not paused:
			var floating := Juice.float_delta(_stage, "-%d" % int(phase.get("damage", 0)), Vector2(_stage.size.x * (0.62 if who == "trainee" else 0.22), 100), 0.6)
			floating.set_meta("motion_effect", true)
		if not paused:
			_sfx.play("tap" if who == "trainee" else "error")
		_event.text = "%s · %d 피해" % ["수련생의 공격" if who == "trainee" else "상대의 공격", int(phase.get("damage", 0))]
	elif who == "victory":
		_event.text = "%s 처치" % str(phase.get("enemyName", "적"))
	elif who == "retreat":
		_event.text = "안전한 곳으로 후퇴해요"
	elif type == "exploration":
		_event.text = str(phase.get("event", "길을 탐색하며 다음 장소로 이동해요"))
	elif type == "event":
		_event.text = str(phase.get("event", "길에서 발견한 흔적을 살펴요"))
		var raw_effect: Variant = phase.get("effect", {})
		var effect: Dictionary = raw_effect if raw_effect is Dictionary else {}
		if effect.has("hp"):
			_event.text += " · HP %+.0f" % float(effect["hp"])
	else:
		_event.text = "%s 조우" % str(phase.get("enemyName", "수호자"))

func _reward_lines() -> Array[String]:
	var lines: Array[String] = []
	# 이미 확정·지급된 결과만 읽는다. 이 화면은 엔진과 저장을 호출하지 않는다.
	var summary := str(result.get("rewardSummary", result.get("summary", "")))
	if not summary.is_empty():
		lines.append(summary)
	var loot: Array = result.get("lootNames", [])
	if not loot.is_empty():
		lines.append("획득 · %s" % ", ".join(loot))
	return lines

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	if font_size >= 20:
		label.theme_type_variation = "TitleLabel"
		label.add_theme_font_override("font", PixelTheme.title_font())
		label.add_theme_font_size_override("font_size", 24)
	else:
		label.add_theme_font_size_override("font_size", 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = "PrimaryButton" if text == "결과 보기" else "Button"
	button.pressed.connect(action)
	return button


func _hp_bar(kind: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.theme = PixelTheme.build()
	bar.theme_type_variation = "PixelGauge" + kind.capitalize()
	bar.custom_minimum_size.y = 12.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar
