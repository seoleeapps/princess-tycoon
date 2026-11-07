extends SceneTree
const Builder = preload("res://addons/seorilabs_game/ui_kit/theme_builder.gd")
const PixelTheme = preload("res://src/ui/pixel/pixel_theme.gd")
func _initialize() -> void:
	var product := Builder.build("res://assets/adventure_ui", "ko")
	product.default_font = PixelTheme.body_font()
	product.set_constant("line_spacing", "Label", 4)
	product.set_font("font", "NumberLabel", PixelTheme.body_font())
	var error := ResourceSaver.save(product, "res://assets/adventure_ui/theme.tres")
	if error != OK:
		push_error("Could not save adventure theme: %s" % error_string(error))
	quit(0 if error == OK else 1)
