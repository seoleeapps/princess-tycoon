extends RefCounted

## 화면 컷아웃 안전 영역을 논리 화면 기준 위·아래 여백으로 바꾼다.
## Android 15 이상은 edge-to-edge가 강제돼 게임이 카메라 컷아웃 뒤까지 그려진다.
## 논리 화면은 canvas_items·keep으로 확대되고 남는 세로 공간은 위아래 화면비 여백이 된다.
## 컷아웃 중 화면비 여백을 넘는 부분만 논리 픽셀로 바꾸고, 도트 격자에 맞게 짝수로 올린다.


static func insets_for(window_size: Vector2, safe_rect: Rect2, base_size: Vector2) -> Vector2:
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return Vector2.ZERO
	var scale := minf(window_size.x / base_size.x, window_size.y / base_size.y)
	var letterbox := (window_size.y - base_size.y * scale) * 0.5
	var top_px := maxf(0.0, safe_rect.position.y - letterbox)
	var bottom_px := maxf(0.0, window_size.y - safe_rect.end.y - letterbox)
	return Vector2(_even_ceil(top_px / scale), _even_ceil(bottom_px / scale))


## 현재 화면의 여백. 테스트는 princess_tycoon/testing/safe_area_insets로 값을 고정한다.
static func current_insets(base_size: Vector2) -> Vector2:
	var forced: Variant = ProjectSettings.get_setting("princess_tycoon/testing/safe_area_insets", Vector2.ZERO)
	if forced is Vector2 and forced != Vector2.ZERO:
		return forced
	if DisplayServer.get_name() == "headless":
		return Vector2.ZERO
	var window_position := Vector2(DisplayServer.window_get_position())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	safe.position -= window_position
	return insets_for(Vector2(DisplayServer.window_get_size()), safe, base_size)


static func _even_ceil(value: float) -> float:
	if value <= 0.0001:
		return 0.0
	return ceilf(value / 2.0 - 0.0001) * 2.0
