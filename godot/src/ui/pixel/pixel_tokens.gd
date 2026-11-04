extends RefCounted

# 방향 A. 아카데미 방의 색과 간격. 스킨 PNG는 scripts/pixel_art/generate.py가 같은 값으로 만든다.
# 글자색은 놓이는 바탕과의 대비가 4.5:1 이상인 조합만 쓴다(CONTRAST_PAIRS).

# 양피지 창 위 글자
const INK := Color("#3a2414")
const INK_MUTED := Color("#7a5a3e")
const ACCENT := Color("#8a4e0a")
const POSITIVE := Color("#2f6a3a")
const NEGATIVE := Color("#a03a32")
const INFO := Color("#2e5a8a")
# 나무 띠·토스트 위 글자
const ON_STRIP := Color("#fbefd0")
const ON_STRIP_MUTED := Color("#d8bf94")
# 버튼 글자
const ON_PRIMARY := Color("#fbf6e4")
const ON_GOLD := Color("#3a2414")
const ON_SECONDARY := Color("#3a2414")
const ON_DANGER := Color("#fbf6e4")
const ON_DISABLED := Color("#6a5c48")

# 면
const PANEL := Color("#f2e2bc")
const INSET := Color("#fbf0d2")
const SELECTED := Color("#fff0b8")
const STRIP := Color("#6a4024")
const STRIP_DARK := Color("#4a2a16")
const SECONDARY := Color("#e8d4a8")
const CHIP := Color("#e6cf9e")
const PRIMARY := Color("#2f7040")
const GOLD := Color("#e3b54a")
const DANGER := Color("#b8483e")
const TOAST := Color("#4a2a16")
const DIM := Color(0.10, 0.06, 0.03, 0.72)

# 게이지 채움 색(스킨 gauge_fill_<이름>과 같다)
const GAUGE := {
	"energy": Color("#5cc06b"), "stress": Color("#e0605a"), "reputation": Color("#f0be3c"),
	"stat": Color("#6aa0f0"), "magic": Color("#b07ae0"), "neutral": Color("#c8a060"),
}

# 고대비 설정의 글자색
const HC_INK := Color("#000000")
const HC_ON_STRIP := Color("#ffffff")
const HC_ON_PRIMARY := Color("#ffffff")

# 간격(논리 px, 모두 짝수)
const GAP := 8
# 2열 격자 간격. 내용 폭 382px을 (382 - 6) / 2 = 188px 두 칸으로 나눠 칸 위치가 짝수가 되게 한다.
const GRID_GAP := 6
const GAP_SMALL := 4
const EDGE := 4
const TOUCH := 44

# 테스트가 확인하는 글자·바탕 조합
const CONTRAST_PAIRS := [
	[INK, PANEL], [INK_MUTED, PANEL], [ACCENT, PANEL], [POSITIVE, PANEL], [NEGATIVE, PANEL], [INFO, PANEL],
	[INK, INSET], [INK_MUTED, INSET], [INK, SELECTED], [INK_MUTED, SELECTED],
	[INK, CHIP], [ON_SECONDARY, SECONDARY], [ON_PRIMARY, PRIMARY], [ON_GOLD, GOLD], [ON_DANGER, DANGER],
	[ON_STRIP, STRIP], [ON_STRIP_MUTED, STRIP], [ON_STRIP, TOAST],
]


static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(color: Color) -> float:
	var channels := [color.r, color.g, color.b]
	for index in channels.size():
		var value: float = channels[index]
		channels[index] = value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
