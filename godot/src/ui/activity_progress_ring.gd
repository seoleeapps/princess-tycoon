extends Control

# 현재 활동 진행률. 16칸 도트 고리로 그리고, 칸은 아트 1px = 논리 2px 격자에 맞춘다.

const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")
const SEGMENTS := 16
const CELL := 4.0

var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(44.0, 44.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func filled_segments() -> int:
	return int(floor(value / 100.0 * SEGMENTS))


func _draw() -> void:
	var center := Vector2(floorf(size.x * 0.25) * 2.0, floorf(size.y * 0.25) * 2.0)
	var radius := 16.0
	var filled := filled_segments()
	for index in SEGMENTS:
		var angle := -PI * 0.5 + TAU * float(index) / SEGMENTS
		var point := center + Vector2(cos(angle), sin(angle)) * radius - Vector2(CELL, CELL) * 0.5
		point = Vector2(floorf(point.x * 0.5) * 2.0, floorf(point.y * 0.5) * 2.0)
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(CELL + 4.0, CELL + 4.0)), PixelTokens.STRIP_DARK)
		draw_rect(Rect2(point, Vector2(CELL, CELL)), PixelTokens.GAUGE["magic"] if index < filled else PixelTokens.SECONDARY)
	draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), PixelTokens.GOLD)
