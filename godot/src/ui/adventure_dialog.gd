extends MarginContainer

const Juice = preload("res://addons/seorilabs_game/ui_kit/juice.gd")
var still := false
var _dim: ColorRect
var _intro: Tween
var _shade: Tween

func attach_to(host: Control) -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.05, 0.1, 0.14, 0.6)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(_dim)
	host.add_child(self)

func _ready() -> void:
	Juice.reduced_motion = still
	# 도트 배율은 유지하고 딤과 창의 불투명도만 바꾼다.
	_intro = Juice.pop_in(self, 0.22, 1.0)
	if not still:
		_dim.modulate.a = 0.0
		_shade = _dim.create_tween()
		_shade.tween_property(_dim, "modulate:a", 1.0, 0.18)

func set_still(value: bool) -> void:
	still = value
	if not still:
		return
	for tween: Tween in [_intro, _shade]:
		if tween != null and tween.is_valid():
			tween.kill()
	modulate.a = 1.0
	if is_instance_valid(_dim):
		_dim.modulate.a = 1.0
