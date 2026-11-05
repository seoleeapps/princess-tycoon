extends RefCounted

# 한글은 음절 사이에서도 줄을 바꿀 수 있어 "은 / 잎 숲"처럼 낱말이 갈린다. 폭에 맞춰 띄어쓰기 자리에 줄바꿈을 넣는다.
# 한 낱말이 폭보다 길 때만 엔진의 자동 줄바꿈이 그 낱말을 나눈다. 폭이 바뀌면 원문에서 다시 나눈다.
static func wrap_at_spaces(label: Label) -> void:
	label.set_meta("source_text", label.text)
	label.resized.connect(func() -> void: rewrap(label))


static func rewrap(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var width := label.size.x
	if width <= 0.0:
		return
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var lines: Array[String] = []
	# 원문의 줄바꿈은 그대로 두고 각 줄 안에서만 나눈다.
	for paragraph: String in str(label.get_meta("source_text", label.text)).split("\n"):
		var line := ""
		for word: String in paragraph.split(" ", false):
			var candidate := word if line.is_empty() else "%s %s" % [line, word]
			if line.is_empty() or font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
				line = candidate
			else:
				lines.append(line)
				line = word
		lines.append(line)
	var wrapped := "\n".join(lines)
	if label.text != wrapped:
		label.text = wrapped


# 글자를 바꿀 때 원문을 새로 기억하고 지금 폭으로 다시 나눈다(알림 띠처럼 글자가 바뀌는 라벨).
static func set_text(label: Label, text: String) -> void:
	label.set_meta("source_text", text)
	label.text = text
	rewrap(label)
