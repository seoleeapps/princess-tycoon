extends RefCounted
# tools/build_adventure_theme.gd가 공통 조립기로 만든 제품 스킨·역할 서체를 그대로 쓴다.
const PRODUCT_THEME := preload("res://assets/adventure_ui/theme.tres")
static func build() -> Theme:
	return PRODUCT_THEME
