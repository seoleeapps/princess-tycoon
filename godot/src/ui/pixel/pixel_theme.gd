extends RefCounted

# 픽셀 Theme. assets/pixel/ui/skins.json(스킨 계약)을 읽어 StyleBoxTexture를 만들고, 일반·고대비 Theme을 한 번씩만 만든다.
# 화면은 theme_type_variation 이름(아래 VARIATIONS)으로 모양을 고르며, 페이지를 다시 그려도 StyleBox를 새로 만들지 않는다.

const PixelTokens = preload("res://src/ui/pixel/pixel_tokens.gd")

const BODY_FONT := "res://assets/fonts/NeoDunggeunmo-Regular.ttf"
const TITLE_FONT := "res://assets/fonts/Galmuri11-Bold.ttf"
const SKINS := "res://assets/pixel/ui/skins.json"
const UI_DIR := "res://assets/pixel/ui/"
const BODY_SIZE := 16
const TITLE_SIZE := 24
const LARGE_SIZE := 32

const BUTTON_VARIATIONS := {
	"primary": ["PixelButtonPrimary", "primary"],
	"gold": ["PixelButtonGold", "gold"],
	"secondary": ["PixelButtonSecondary", "secondary"],
	"ghost": ["PixelButtonSecondary", "secondary"],
	"danger": ["PixelButtonDanger", "danger"],
	"disabled": ["PixelButtonSecondary", "secondary"],
}
const PANEL_VARIATIONS := {
	"window": "window", "window_gold": "window_gold", "window_accent": "window_accent",
	"window_selected": "window_selected", "inset": "inset", "strip": "strip", "sheet": "sheet",
	"toast": "toast", "chip": "chip",
}
const GAUGES := ["energy", "stress", "reputation", "stat", "magic", "neutral"]

static var _themes := {}
static var _manifest := {}
static var _doubled := {}
static var _body_variation: FontVariation
static var _title_variation: FontVariation


static func build(high_contrast: bool = false) -> Theme:
	if _themes.has(high_contrast):
		return _themes[high_contrast]
	var theme := Theme.new()
	var body := body_font()
	theme.default_font = body
	theme.default_font_size = BODY_SIZE
	var ink := PixelTokens.HC_INK if high_contrast else PixelTokens.INK

	theme.set_color("font_color", "Label", ink)
	theme.set_constant("line_spacing", "Label", 4)

	_button_type(theme, "Button", "secondary", high_contrast)
	for variant: String in BUTTON_VARIATIONS:
		var entry: Array = BUTTON_VARIATIONS[variant]
		theme.set_type_variation(entry[0], "Button")
		_button_type(theme, entry[0], entry[1], high_contrast)
	# 좁은 칸(분류 탭, 스테퍼)에 쓰는 내용 여백이 작은 버튼
	for kind: String in ["secondary", "gold", "primary"]:
		var compact_name := "PixelButtonCompact" + kind.capitalize()
		theme.set_type_variation(compact_name, "Button")
		_button_type(theme, compact_name, kind, high_contrast, true)
	# 목록 행 전체를 누르는 투명 버튼(눌림·포커스만 표시)
	theme.set_type_variation("PixelRowButton", "Button")
	var row_empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "disabled"]:
		theme.set_stylebox(state, "PixelRowButton", row_empty)
	theme.set_stylebox("pressed", "PixelRowButton", skin("inset", high_contrast))
	theme.set_stylebox("hover_pressed", "PixelRowButton", skin("inset", high_contrast))
	theme.set_stylebox("focus", "PixelRowButton", skin("focus", high_contrast))
	theme.set_type_variation("PixelTab", "Button")
	_tab_type(theme, "PixelTab", "tab_normal", PixelTokens.HC_ON_STRIP if high_contrast else PixelTokens.ON_STRIP, high_contrast)
	theme.set_type_variation("PixelTabSelected", "Button")
	_tab_type(theme, "PixelTabSelected", "tab_selected", ink, high_contrast)

	theme.set_stylebox("panel", "PanelContainer", skin("window", high_contrast))
	for variation: String in PANEL_VARIATIONS:
		var type_name := "Pixel" + variation.to_pascal_case()
		theme.set_type_variation(type_name, "PanelContainer")
		theme.set_stylebox("panel", type_name, skin(PANEL_VARIATIONS[variation], high_contrast))

	theme.set_stylebox("background", "ProgressBar", skin("gauge_bg", high_contrast))
	theme.set_stylebox("fill", "ProgressBar", skin("gauge_fill_neutral", high_contrast))
	theme.set_color("font_color", "ProgressBar", ink)
	for gauge: String in GAUGES:
		var type_name := "PixelGauge" + gauge.capitalize()
		theme.set_type_variation(type_name, "ProgressBar")
		theme.set_stylebox("background", type_name, skin("gauge_bg", high_contrast))
		theme.set_stylebox("fill", type_name, skin("gauge_fill_" + gauge, high_contrast))

	for state in ["normal", "focus", "read_only"]:
		theme.set_stylebox(state, "LineEdit", skin("inset" if state != "focus" else "focus", high_contrast))
	theme.set_color("font_color", "LineEdit", ink)
	theme.set_color("font_placeholder_color", "LineEdit", PixelTokens.INK_MUTED)
	theme.set_color("caret_color", "LineEdit", ink)
	theme.set_color("selection_color", "LineEdit", Color(PixelTokens.GOLD, 0.6))

	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		theme.set_stylebox(state, "CheckButton", empty)
	theme.set_stylebox("focus", "CheckButton", skin("focus", high_contrast))
	var suffix := "_hc" if high_contrast else ""
	theme.set_icon("checked", "CheckButton", load(UI_DIR + "toggle_on%s.png" % suffix))
	theme.set_icon("unchecked", "CheckButton", load(UI_DIR + "toggle_off%s.png" % suffix))
	theme.set_icon("checked_disabled", "CheckButton", load(UI_DIR + "toggle_disabled%s.png" % suffix))
	theme.set_icon("unchecked_disabled", "CheckButton", load(UI_DIR + "toggle_disabled%s.png" % suffix))
	theme.set_color("font_color", "CheckButton", ink)

	theme.set_stylebox("scroll", "VScrollBar", skin("scroll_bg", high_contrast))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(state, "VScrollBar", skin("scroll_grabber", high_contrast))

	theme.set_stylebox("slider", "HSlider", skin("gauge_bg", high_contrast))
	theme.set_stylebox("grabber_area", "HSlider", skin("gauge_fill_neutral", high_contrast))
	theme.set_stylebox("grabber_area_highlight", "HSlider", skin("gauge_fill_neutral", high_contrast))
	_themes[high_contrast] = theme
	return theme


# 본문 폰트. 글자 높이 16px에 폰트 자체 줄 간격 3px이 더해져 한 줄이 19px이 되므로,
# 아래 여백 1px을 더해 줄 높이를 20px(짝수)로 맞춘다. 창과 게이지가 2px 도트 격자에 놓이게 하기 위함이다.
# 1배 도트를 nearest로 2배 키운 텍스처. 1:1로 그리면 뷰포트 필터 설정과 무관하게 도트가 선명하다.
static func doubled_texture(path: String) -> Texture2D:
	if _doubled.has(path):
		return _doubled[path]
	if not ResourceLoader.exists(path):
		push_error("Pixel texture missing: %s" % path)
		return null
	var image := (load(path) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	_doubled[path] = texture
	return texture


static func body_font() -> Font:
	if _body_variation == null:
		var file := load(BODY_FONT) as FontFile
		# Neo둥근모에 없는 기호(↑, →, ★ 등)는 Galmuri로 대신 그린다.
		file.fallbacks = [load(TITLE_FONT) as Font]
		_body_variation = FontVariation.new()
		_body_variation.base_font = file
		_body_variation.spacing_bottom = 1
		_body_variation.fallbacks = file.fallbacks
	return _body_variation


static func title_font() -> Font:
	if _title_variation == null:
		_title_variation = FontVariation.new()
		_title_variation.base_font = load(TITLE_FONT) as Font
	return _title_variation


static func font_file(variation: Font) -> Font:
	return (variation as FontVariation).base_font if variation is FontVariation else variation


static func skin(name: String, high_contrast: bool = false) -> StyleBoxTexture:
	var entry: Dictionary = _skins().get(name, {}) as Dictionary
	var path := UI_DIR + name + ("_hc" if high_contrast else "") + ".png"
	if entry.is_empty() or not ResourceLoader.exists(path):
		push_error("Pixel skin missing: %s" % path)
		return null
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	var margin: Array = entry.get("margin", [0, 0, 0, 0])
	var content: Array = entry.get("content", [0, 0, 0, 0])
	style.texture_margin_left = float(margin[0])
	style.texture_margin_top = float(margin[1])
	style.texture_margin_right = float(margin[2])
	style.texture_margin_bottom = float(margin[3])
	style.content_margin_left = float(content[0])
	style.content_margin_top = float(content[1])
	style.content_margin_right = float(content[2])
	style.content_margin_bottom = float(content[3])
	if bool(entry.get("tile", false)):
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return style


static func button_variation(variant: String) -> String:
	return str((BUTTON_VARIATIONS.get(variant, BUTTON_VARIATIONS["secondary"]) as Array)[0])


static func panel_variation(tone: String) -> String:
	return "Pixel" + tone.to_pascal_case() if PANEL_VARIATIONS.has(tone) else "PixelWindow"


static func gauge_variation(kind: String) -> String:
	return "PixelGauge" + (kind if GAUGES.has(kind) else "neutral").capitalize()


static func _skins() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SKINS))
		if parsed is Dictionary:
			_manifest = (parsed as Dictionary).get("skins", {}) as Dictionary
	return _manifest


static func _button_type(theme: Theme, type_name: String, kind: String, high_contrast: bool, compact: bool = false) -> void:
	var normal := _compact(skin("button_%s_normal" % kind, high_contrast), compact)
	var pressed := _compact(skin("button_%s_pressed" % kind, high_contrast), compact)
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, normal)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("hover_pressed", type_name, pressed)
	theme.set_stylebox("disabled", type_name, _compact(skin("button_%s_disabled" % kind, high_contrast), compact))
	theme.set_stylebox("focus", type_name, skin("focus", high_contrast))
	var text := _button_text(kind, high_contrast)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type_name, text)
	theme.set_color("font_disabled_color", type_name, PixelTokens.HC_INK if high_contrast else PixelTokens.ON_DISABLED)
	theme.set_constant("h_separation", type_name, 8)


static func _compact(style: StyleBoxTexture, compact: bool) -> StyleBoxTexture:
	if compact and style != null:
		style.content_margin_left = 6.0
		style.content_margin_right = 6.0
	return style


static func _tab_type(theme: Theme, type_name: String, skin_name: String, text: Color, high_contrast: bool) -> void:
	var style := skin(skin_name, high_contrast)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, type_name, style)
	theme.set_stylebox("focus", type_name, skin("focus", high_contrast))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type_name, text)
	theme.set_constant("h_separation", type_name, 0)


static func _button_text(kind: String, high_contrast: bool) -> Color:
	if high_contrast:
		return PixelTokens.HC_ON_PRIMARY if kind in ["primary", "danger"] else PixelTokens.HC_INK
	match kind:
		"primary": return PixelTokens.ON_PRIMARY
		"gold": return PixelTokens.ON_GOLD
		"danger": return PixelTokens.ON_DANGER
		_: return PixelTokens.ON_SECONDARY
