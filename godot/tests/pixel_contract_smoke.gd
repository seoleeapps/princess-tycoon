extends SceneTree

# 픽셀 UI 계약(설계 2026-11-pixel-raising-ui PX-01~04).
# 폰트·글리프, 렌더 설정, 스킨 계약, 페이퍼돌 합성기를 확인한다.

const FONT_BODY := "res://assets/fonts/NeoDunggeunmo-Regular.ttf"
const FONT_TITLE := "res://assets/fonts/Galmuri11-Bold.ttf"
const SKINS := "res://assets/pixel/ui/skins.json"
const SPRITE := "res://assets/pixel/sprites/trainee.json"
const REFERENCE_DIR := "res://assets/pixel/sprites/reference/"
const BUTTON_KINDS := ["primary", "gold", "secondary", "danger"]
const BUTTON_STATES := ["normal", "pressed", "disabled"]
const PRESETS := ["balanced", "martial", "scholar", "artist", "leader", "care", "explorer", "prosperity", "custom"]
const EQUIPMENT := {
	"outfit": ["OUTFIT_PLAIN", "OUTFIT_FORMAL", "OUTFIT_NOBLE", "OUTFIT_ACTIVE", "OUTFIT_STAGE"],
	"armor": ["ARM_LEATHER", "ARM_PLATE", "ARM_ROBE"],
	"weapon": ["WPN_DAGGER", "WPN_SWORD", "WPN_RAPIER", "WPN_WAND"],
	"accessory": ["ACC_RIBBON", "ACC_JEWEL"],
}
const REFERENCES := {
	"balanced_plain_smile": ["balanced", {}, "smile"],
	"scholar_formal_robe_wand": ["scholar", {"outfit": "OUTFIT_FORMAL", "armor": "ARM_ROBE", "weapon": "WPN_WAND", "accessory": "ACC_RIBBON"}, "focus"],
	"martial_active_plate_sword": ["martial", {"outfit": "OUTFIT_ACTIVE", "armor": "ARM_PLATE", "weapon": "WPN_SWORD", "accessory": "ACC_JEWEL"}, "smile"],
}

var _failures: Array[String] = []
var _passes := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[PIXEL] Pixel UI contract")
	_check_fonts()
	_check_render_settings()
	_check_skins()
	_check_compositor()
	_finish()


func _check_fonts() -> void:
	var pixel_theme_script: Script = load("res://src/ui/pixel/pixel_theme.gd") if ResourceLoader.exists("res://src/ui/pixel/pixel_theme.gd") else null
	_check(pixel_theme_script != null, "PX-01 픽셀 테마 스크립트 존재")
	if pixel_theme_script == null:
		return
	var theme: Theme = pixel_theme_script.call("build", false)
	var body_font: Font = theme.default_font
	var body_file: Font = pixel_theme_script.call("font_file", body_font)
	_check(body_file != null and body_file.resource_path == FONT_BODY and theme.default_font_size == 16, "PX-01 본문 기본 폰트 Neo둥근모 16px")
	var title_file: Font = pixel_theme_script.call("font_file", pixel_theme_script.call("title_font"))
	_check(title_file != null and title_file.resource_path == FONT_TITLE, "PX-01 제목 폰트 Galmuri11 Bold")
	var probe := Label.new()
	probe.theme = theme
	probe.text = "줄\n높이"
	root.add_child(probe)
	var two_lines := probe.get_combined_minimum_size().y
	probe.text = "줄"
	var one_line := probe.get_combined_minimum_size().y
	probe.free()
	_check(int(one_line) % 2 == 0 and int(two_lines) % 2 == 0, "PX-05 본문 줄 높이가 2px 격자에 맞음", "one=%s two=%s" % [one_line, two_lines])
	for path in [FONT_BODY, FONT_TITLE]:
		var import_text := FileAccess.get_file_as_string(path + ".import")
		_check(import_text.contains("antialiasing=0") and import_text.contains("hinting=0") and import_text.contains("subpixel_positioning=0"),
			"PX-01 %s 안티앨리어싱·힌팅·서브픽셀 끔" % path.get_file())
	# UI·데이터 문자열은 본문 폰트 자체로 그려야 한다. 대체 폰트 글리프는 줄 높이를 바꿔 2px 격자를 깬다.
	# Galmuri 대체는 플레이어가 입력한 이름 같은 예외 문자를 위한 안전망으로만 둔다.
	var missing: Array[String] = []
	var fallback_only: Array[String] = []
	for character: String in _ui_characters():
		if not _font_covers(body_font, character):
			missing.append(character)
		elif not body_file.has_char(character.unicode_at(0)):
			fallback_only.append(character)
	_check(missing.is_empty(), "PX-01 UI 문자열 글리프 전부 표시", "missing=%s" % "".join(missing.slice(0, 40)))
	_check(fallback_only.is_empty(), "PX-01 UI 문자열이 대체 폰트 없이 본문 폰트로 그려짐", "fallback=%s" % "".join(fallback_only))


func _check_render_settings() -> void:
	_check(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", 1)) == 0, "PX-02 기본 텍스처 필터 nearest")
	_check(bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", false)), "PX-02 2D 변환 픽셀 스냅")
	_check(bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel", false)), "PX-02 2D 정점 픽셀 스냅")
	var bad_imports: Array[String] = []
	for path: String in _files_under("res://assets/pixel", ".png"):
		var import_text := FileAccess.get_file_as_string(path + ".import")
		if not import_text.contains("compress/mode=0") or not import_text.contains("mipmaps/generate=false"):
			bad_imports.append(path.get_file())
	_check(bad_imports.is_empty(), "PX-02 픽셀 PNG 무손실·mipmap 끔", ", ".join(bad_imports.slice(0, 10)))


func _check_skins() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(SKINS))
	_check(manifest is Dictionary and (manifest as Dictionary).has("skins"), "PX-03 스킨 계약 로드")
	if not manifest is Dictionary:
		return
	var skins: Dictionary = manifest["skins"]
	var problems: Array[String] = []
	for name: String in skins:
		var entry: Dictionary = skins[name]
		for suffix in ["", "_hc"]:
			var path := "res://assets/pixel/ui/%s%s.png" % [name, suffix]
			if not ResourceLoader.exists(path):
				problems.append("missing %s" % path.get_file())
				continue
			var image := (load(path) as Texture2D).get_image()
			if image.get_width() != int(entry["size"][0]) or image.get_height() != int(entry["size"][1]):
				problems.append("size %s" % path.get_file())
			if not _is_doubled(image):
				problems.append("grid %s" % path.get_file())
		for value in entry["size"] + entry["margin"]:
			if int(value) % 2 != 0:
				problems.append("odd %s" % name)
	for kind: String in BUTTON_KINDS:
		for state: String in BUTTON_STATES:
			if not skins.has("button_%s_%s" % [kind, state]):
				problems.append("state button_%s_%s" % [kind, state])
	for required in ["window", "window_gold", "window_accent", "window_selected", "inset", "strip", "sheet", "toast", "chip", "focus", "tab_normal", "tab_selected", "gauge_bg"]:
		if not skins.has(required):
			problems.append("component %s" % required)
	_check(problems.is_empty(), "PX-03 스킨 파일·크기·짝수 여백·2배 격자·상태", ", ".join(problems.slice(0, 12)))

	var pixel_theme_script: Script = load("res://src/ui/pixel/pixel_theme.gd") if ResourceLoader.exists("res://src/ui/pixel/pixel_theme.gd") else null
	if pixel_theme_script == null:
		return
	var theme: Theme = pixel_theme_script.call("build", false)
	var button_style := theme.get_stylebox("normal", "Button") as StyleBoxTexture
	_check(button_style != null and button_style.texture != null and button_style.texture.resource_path.ends_with("button_secondary_normal.png"), "PX-03 테마 버튼이 스킨 텍스처 사용")
	var hc_theme: Theme = pixel_theme_script.call("build", true)
	var hc_style := hc_theme.get_stylebox("normal", "Button") as StyleBoxTexture
	_check(hc_style != null and hc_style.texture.resource_path.ends_with("button_secondary_normal_hc.png"), "PX-03 고대비 테마가 고대비 스킨 사용")


func _check_compositor() -> void:
	var path := "res://src/ui/pixel/trainee_compositor.gd"
	var compositor_script: Script = load(path) if ResourceLoader.exists(path) else null
	_check(compositor_script != null, "PX-04 페이퍼돌 합성기 존재")
	if compositor_script == null:
		return
	var compositor: RefCounted = compositor_script.new()
	_check(bool(compositor.call("load_sprite", SPRITE)), "PX-04 페이퍼돌 원본 로드")
	for name: String in REFERENCES:
		var args: Array = REFERENCES[name]
		var image: Image = compositor.call("compose", args[0], args[1], args[2])
		var reference := (load(REFERENCE_DIR + name + ".png") as Texture2D).get_image()
		_check(_same_pixels(image, reference), "PX-04 생성기 기준 합성과 픽셀 일치: %s" % name)
	var base: Image = compositor.call("compose", "balanced", {}, "smile")
	var with_sword: Image = compositor.call("compose", "balanced", {"weapon": "WPN_SWORD"}, "smile")
	var changed := _changed_bounds(base, with_sword)
	_check(changed.size.x > 0 and changed.position.x >= 26, "PX-04 무기 장착은 무기 영역만 바꿈", str(changed))
	var scholar: Image = compositor.call("compose", "scholar", {}, "smile")
	_check(not _same_pixels(base, scholar), "PX-04 성장 분야가 제복 색을 바꿈")
	var errors := 0
	for preset: String in PRESETS:
		for slot: String in EQUIPMENT:
			for item: String in EQUIPMENT[slot]:
				var composed: Image = compositor.call("compose", preset, {slot: item}, "smile")
				if composed == null or composed.get_width() != 40:
					errors += 1
	_check(errors == 0, "PX-04 장비 14종 × 방향 9종 합성", "errors=%d" % errors)
	var first: Image = compositor.call("compose", "leader", {"outfit": "OUTFIT_NOBLE"}, "smile")
	var second: Image = compositor.call("compose", "leader", {"outfit": "OUTFIT_NOBLE"}, "smile")
	_check(_same_pixels(first, second), "PX-04 같은 입력은 같은 결과")


func _ui_characters() -> Array[String]:
	var seen := {}
	var sources: Array[String] = []
	for path: String in _files_under("res://data", ".json"):
		sources.append(FileAccess.get_file_as_string(path))
	var literal := RegEx.new()
	literal.compile("\"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"")
	for directory in ["res://src/ui", "res://src/core"]:
		for path: String in _files_under(directory, ".gd"):
			for found in literal.search_all(FileAccess.get_file_as_string(path)):
				sources.append(found.get_string(1))
	for source: String in sources:
		for index in source.length():
			var code := source.unicode_at(index)
			if code > 0x7f:
				seen[char(code)] = true
	var result: Array[String] = []
	for key in seen:
		result.append(str(key))
	return result


func _font_covers(font: Font, character: String) -> bool:
	if font.has_char(character.unicode_at(0)):
		return true
	for fallback: Font in font.fallbacks:
		if fallback.has_char(character.unicode_at(0)):
			return true
	return false


func _files_under(directory: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(extension):
			result.append(directory.path_join(file_name))
	for sub in dir.get_directories():
		result.append_array(_files_under(directory.path_join(sub), extension))
	return result


func _is_doubled(image: Image) -> bool:
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var color := image.get_pixel(x, y)
			if image.get_pixel(x + 1, y) != color or image.get_pixel(x, y + 1) != color or image.get_pixel(x + 1, y + 1) != color:
				return false
	return true


func _same_pixels(a: Image, b: Image) -> bool:
	if a == null or b == null or a.get_size() != b.get_size():
		return false
	for y in a.get_height():
		for x in a.get_width():
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if pa.a8 == 0 and pb.a8 == 0:
				continue
			if pa.to_rgba32() != pb.to_rgba32():
				return false
	return true


func _changed_bounds(a: Image, b: Image) -> Rect2i:
	var min_x := 9999
	var max_x := -1
	var min_y := 9999
	var max_y := -1
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y).to_rgba32() != b.get_pixel(x, y).to_rgba32():
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		_passes += 1
		print("[PASS] %s" % label)
	else:
		_failures.append(label)
		push_error("[FAIL] %s %s" % [label, detail])


func _finish() -> void:
	if _failures.is_empty():
		print("[PIXEL] PASS checks=%d" % _passes)
		quit(0)
		return
	print("[PIXEL] FAIL passed=%d failed=%d" % [_passes, _failures.size()])
	quit(1)
