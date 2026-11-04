"""방향별 창·버튼·게이지·탭 재질. 모두 1배 아트 좌표로 그린다."""
from __future__ import annotations

from pixellib import Art, rgb, shade

STYLES = {
    # A. 아카데미 방: 호두나무 띠와 양피지 창
    "wood": {
        "outline": rgb("2e1a0e"), "panel": rgb("f2e2bc"), "panel_hi": rgb("fff4d6"), "panel_lo": rgb("d6bd8e"),
        "border": rgb("8a5a34"), "strip": rgb("6a4024"), "strip_hi": rgb("8e5a34"), "strip_lo": rgb("4a2a16"),
        "text": rgb("3a2414"), "muted": rgb("7a5a3e"), "on_strip": rgb("fbefd0"), "on_strip_muted": rgb("d8bf94"),
        "primary": rgb("2f7040"), "primary_text": rgb("fbf6e4"), "gold": rgb("e3b54a"), "gold_text": rgb("3a2414"),
        "secondary": rgb("e8d4a8"), "secondary_text": rgb("3a2414"), "disabled": rgb("b8a888"), "disabled_text": rgb("7a6e58"),
        "gauge_bg": rgb("4a2e1c"), "selected": rgb("f2e2bc"), "selected_edge": rgb("e3b54a"),
    },
    # B. 왕실 상태 장부: 남색 창, 흰 테두리, 금색 모서리
    "ledger": {
        "outline": rgb("0a0c1c"), "panel": rgb("232a66"), "panel_hi": rgb("2e3680"), "panel_lo": rgb("1a1f4e"),
        "border": rgb("e8ecff"), "border2": rgb("8a93d6"), "corner": rgb("e9b949"),
        "text": rgb("f4f2ff"), "muted": rgb("aab0e0"), "accent": rgb("ffd66e"),
        "primary": rgb("3e4ab0"), "primary_text": rgb("ffffff"), "gold": rgb("e9b949"), "gold_text": rgb("1a1430"),
        "secondary": rgb("2e3680"), "secondary_text": rgb("f4f2ff"), "disabled": rgb("2a2e58"), "disabled_text": rgb("6e74a8"),
        "gauge_bg": rgb("0f1230"), "cursor_bar": rgb("3a46a8"), "bg": rgb("12153a"),
    },
    # C. 그림책 디오라마: 파스텔, 두꺼운 둥근 테두리
    "storybook": {
        "outline": rgb("5a4468"), "panel": rgb("fffaf0"), "panel_hi": rgb("ffffff"), "panel_lo": rgb("f2e4d6"),
        "border": rgb("ffffff"), "frame": rgb("f4a8bc"), "frame_lo": rgb("d8849c"),
        "text": rgb("4a3658"), "muted": rgb("6e5a80"),
        "primary": rgb("7fd6ae"), "primary_text": rgb("2a4a3a"), "gold": rgb("ffd56a"), "gold_text": rgb("5a4020"),
        "secondary": rgb("cfe0ff"), "secondary_text": rgb("344a7a"), "disabled": rgb("e2dce6"), "disabled_text": rgb("9a90a4"),
        "gauge_bg": rgb("e8dcef"), "bg": rgb("fde8ee"), "tab": rgb("fff4f6"),
    },
}

METER_COLORS = {"energy": rgb("5cc06b"), "stress": rgb("e0605a"), "reputation": rgb("f0be3c"),
                "stat": rgb("6aa0f0"), "magic": rgb("b07ae0")}


def cut_corners(a: Art, x: int, y: int, w: int, h: int, size: int = 1, color=(0, 0, 0, 0)) -> None:
    for i in range(size):
        for j in range(size - i):
            for cx, cy in ((x + j, y + i), (x + w - 1 - j, y + i), (x + j, y + h - 1 - i), (x + w - 1 - j, y + h - 1 - i)):
                a.px(cx, cy, color)


def parchment(a: Art, x: int, y: int, w: int, h: int, s=STYLES["wood"], under=None) -> None:
    a.rect(x, y, w, h, s["outline"])
    a.rect(x + 1, y + 1, w - 2, h - 2, s["border"])
    a.rect(x + 2, y + 2, w - 4, h - 4, s["panel"])
    a.hline(x + 2, y + 2, w - 4, s["panel_hi"])
    a.hline(x + 2, y + h - 3, w - 4, s["panel_lo"])
    a.vline(x + w - 3, y + 2, h - 4, s["panel_lo"])
    cut_corners(a, x, y, w, h, 1, under if under else (0, 0, 0, 0))


def wood_strip(a: Art, x: int, y: int, w: int, h: int, s=STYLES["wood"]) -> None:
    a.rect(x, y, w, h, s["strip"])
    a.hline(x, y, w, s["outline"])
    a.hline(x, y + 1, w, s["strip_hi"])
    a.hline(x, y + h - 2, w, s["strip_lo"])
    a.hline(x, y + h - 1, w, s["outline"])
    for gx in range(x + 7, x + w, 23):
        a.hline(gx, y + 5, 6, s["strip_lo"])
        a.hline(gx + 9, y + h - 6, 5, s["strip_lo"])


def navy_window(a: Art, x: int, y: int, w: int, h: int, s=STYLES["ledger"]) -> None:
    a.rect(x, y, w, h, s["outline"])
    a.rect(x + 1, y + 1, w - 2, h - 2, s["border"])
    a.rect(x + 2, y + 2, w - 4, h - 4, s["outline"])
    # 위에서 아래로 3단 띠 명암
    inner_h = h - 6
    band = max(1, inner_h // 3)
    a.rect(x + 3, y + 3, w - 6, inner_h, s["panel"])
    a.rect(x + 3, y + 3, w - 6, band, s["panel_hi"])
    a.rect(x + 3, y + 3 + inner_h - band, w - 6, band, s["panel_lo"])
    a.hline(x + 3, y + 3, w - 6, s["border2"])
    for cx, cy, dx, dy in ((x + 1, y + 1, 1, 1), (x + w - 2, y + 1, -1, 1), (x + 1, y + h - 2, 1, -1), (x + w - 2, y + h - 2, -1, -1)):
        for i in range(3):
            a.px(cx + dx * i, cy, s["corner"])
            a.px(cx, cy + dy * i, s["corner"])
    cut_corners(a, x, y, w, h, 1, s.get("bg_under", (0, 0, 0, 0)))


def story_frame(a: Art, x: int, y: int, w: int, h: int, s=STYLES["storybook"], fill=True, under=None) -> None:
    under = under if under is not None else s["bg"]
    a.rect(x, y, w, h, s["outline"])
    a.rect(x + 1, y + 1, w - 2, h - 2, s["frame"])
    a.hline(x + 1, y + 1, w - 2, s["border"])
    a.hline(x + 1, y + h - 2, w - 2, s["frame_lo"])
    a.rect(x + 3, y + 3, w - 6, h - 6, s["outline"])
    if fill:
        a.rect(x + 4, y + 4, w - 8, h - 8, s["panel"])
        a.hline(x + 4, y + h - 5, w - 8, s["panel_lo"])
    cut_corners(a, x, y, w, h, 2, under)
    cut_corners(a, x + 3, y + 3, w - 6, h - 6, 1, s["frame"])


def button(a: Art, x: int, y: int, w: int, h: int, kind: str, s: dict, state: str = "normal", under=None) -> None:
    face = {"primary": s["primary"], "gold": s["gold"], "secondary": s["secondary"], "disabled": s["disabled"]}[kind if state != "disabled" else "disabled"]
    depth = 0 if state == "pressed" else 2
    top = y + (2 - depth)
    a.rect(x, top, w, h - (2 - depth), s["outline"])
    a.rect(x + 1, top + 1, w - 2, h - 2 - (2 - depth), shade(face, 0.72))
    a.rect(x + 1, top + 1, w - 2, h - 2 - (2 - depth) - depth, face)
    a.hline(x + 2, top + 1, w - 4, shade(face, 1.18))
    cut_corners(a, x, top, w, h - (2 - depth), 1, under if under else (0, 0, 0, 0))
    if state == "pressed":
        a.rect(x, y, w, 2, under if under else (0, 0, 0, 0))


def gauge(a: Art, x: int, y: int, w: int, h: int, ratio: float, color, bg, outline, segment: int = 3) -> None:
    a.rect(x, y, w, h, outline)
    a.rect(x + 1, y + 1, w - 2, h - 2, bg)
    fill_w = int((w - 2) * max(0.0, min(1.0, ratio)))
    a.rect(x + 1, y + 1, fill_w, h - 2, color)
    a.hline(x + 1, y + 1, fill_w, shade(color, 1.25))
    if segment:
        for sx in range(x + 1 + segment, x + 1 + fill_w, segment + 1):
            a.vline(sx, y + 1, h - 2, shade(color, 0.7))


def bubble(a: Art, x: int, y: int, w: int, h: int, outline=rgb("2b1d24"), fill=rgb("fffaf2")) -> None:
    a.rect(x, y, w, h, outline)
    a.rect(x + 1, y + 1, w - 2, h - 2, fill)
    cut_corners(a, x, y, w, h, 1)
    tx = x + w // 2 - 2
    a.rect(tx, y + h - 1, 4, 1, fill)
    a.px(tx - 1, y + h - 1, outline)
    a.px(tx + 4, y + h - 1, outline)
    a.rect(tx + 1, y + h, 2, 1, fill)
    a.px(tx, y + h, outline)
    a.px(tx + 3, y + h, outline)
    a.px(tx + 1, y + h + 1, outline)
    a.px(tx + 2, y + h + 1, outline)
