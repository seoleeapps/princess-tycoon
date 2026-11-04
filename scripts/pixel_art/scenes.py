"""아카데미 장면 배경을 1배 아트로 그린다. 같은 구조에 테마 팔레트만 바꾼다."""
from __future__ import annotations

from pixellib import Art, rgb, seeded, shade

THEMES = {
    "warm": {
        "wall": "c9a27a", "wall_dark": "b08a64", "wall_stripe": "d4b08a",
        "wood": "7a4a2c", "wood_dark": "54301a", "wood_light": "9c6438", "line": "2e180c",
        "floor": "8c5a34", "floor_dark": "6e4426", "floor_light": "a46c40",
        "sky": "9fd3ff", "sky_light": "d9f0ff", "glass_frame": "5a3a22",
        "rug": "a83a3e", "rug_dark": "7a2430", "rug_trim": "e3b54a",
        "beam": "f6e3b0", "banner": "34407a", "banner_trim": "e3b54a",
        "books": ["a83a3e", "34407a", "3e7a52", "c48a2e", "6e3a7a", "2e6a7a", "d8c39a"],
    },
    "night": {
        "wall": "3a3f6e", "wall_dark": "2c3058", "wall_stripe": "444a7e",
        "wood": "4a3044", "wood_dark": "2e1c2e", "wood_light": "634260", "line": "120c1c",
        "floor": "3e2c48", "floor_dark": "2c1f36", "floor_light": "4e3a5a",
        "sky": "283c7a", "sky_light": "4a62a8", "glass_frame": "241a30",
        "rug": "6e2a50", "rug_dark": "4a1a38", "rug_trim": "d8b048",
        "beam": "8aa0e0", "banner": "8a2e3e", "banner_trim": "d8b048",
        "books": ["8a2e3e", "2e4a8a", "2e6a4a", "a8782a", "5a2e6a", "2e5a6a", "a89a7a"],
    },
    "pastel": {
        "wall": "fde8d4", "wall_dark": "f2d2bc", "wall_stripe": "fff3e6",
        "wood": "c99a76", "wood_dark": "a87a5a", "wood_light": "e2b896", "line": "6a4a5a",
        "floor": "e8c8a8", "floor_dark": "d6b494", "floor_light": "f4dcc0",
        "sky": "b8e4ff", "sky_light": "e8f6ff", "glass_frame": "a87a5a",
        "rug": "f2a0b4", "rug_dark": "d8809a", "rug_trim": "fff0b0",
        "beam": "fffbe8", "banner": "9ab8f0", "banner_trim": "fff0b0",
        "books": ["f2a0b4", "9ab8f0", "a8dcb0", "f6d08a", "c8a8e8", "8cd0d8", "fff3e6"],
    },
}


def _c(theme: dict, key: str):
    return rgb(theme[key])


def study_room(w: int, h: int, theme_name: str = "warm", seed: int = 7) -> Art:
    t = THEMES[theme_name]
    rng = seeded(seed)
    a = Art(w, h, _c(t, "wall"))
    floor_y = int(h * 0.68)
    wains_y = int(h * 0.48)

    # 벽지 세로 줄무늬
    for x in range(0, w, 8):
        a.vline(x, 0, wains_y, _c(t, "wall_stripe"))
    # 천장 몰딩
    a.rect(0, 0, w, 4, _c(t, "wood"))
    a.hline(0, 4, w, _c(t, "wood_dark"))
    a.hline(0, 1, w, _c(t, "wood_light"))

    # 아치 창문
    wx, ww = int(w * 0.52), int(w * 0.30)
    wy, wh = 14, wains_y - 18
    a.rect(wx - 2, wy + 6, ww + 4, wh - 4, _c(t, "glass_frame"))
    a.ellipse(wx - 2, wy - 2, wx + ww + 1, wy + 14, _c(t, "glass_frame"))
    a.rect(wx, wy + 6, ww, wh - 8, _c(t, "sky"))
    a.ellipse(wx, wy, wx + ww - 1, wy + 12, _c(t, "sky"))
    for yy in range(wy, wy + wh - 2):
        if yy % 3 == 0:
            a.hline(wx + 2, yy, ww - 4, _c(t, "sky_light")) if yy < wy + 20 else None
    a.vline(wx + ww // 2, wy, wh - 2, _c(t, "glass_frame"))
    a.hline(wx, wy + wh // 2, ww, _c(t, "glass_frame"))
    a.rect(wx - 4, wy + wh - 2, ww + 8, 3, _c(t, "wood_light"))
    a.hline(wx - 4, wy + wh + 1, ww + 8, _c(t, "wood_dark"))

    # 아카데미 문장 깃발(창 왼쪽)
    bx = int(w * 0.36)
    a.rect(bx, 10, 14, 22, _c(t, "banner"))
    a.poly([(bx, 32), (bx + 13, 32), (bx + 7, 37)], _c(t, "banner"))
    a.box(bx, 10, 14, 22, _c(t, "banner_trim"))
    a.rect(bx + 5, 16, 4, 6, _c(t, "banner_trim"))
    a.rect(bx + 4, 18, 6, 2, _c(t, "banner_trim"))
    a.hline(bx - 2, 9, 18, _c(t, "wood_dark"))

    # 징두리 판벽
    a.rect(0, wains_y, w, floor_y - wains_y, _c(t, "wood"))
    a.hline(0, wains_y, w, _c(t, "wood_light"))
    a.hline(0, wains_y + 1, w, _c(t, "wood_dark"))
    for x in range(6, w, 24):
        a.box(x, wains_y + 5, 18, floor_y - wains_y - 9, _c(t, "wood_dark"))
        a.hline(x + 1, wains_y + 6, 16, _c(t, "wood_light"))

    # 책장(왼쪽)
    sx, sw = 4, int(w * 0.26)
    sy, sh = 10, floor_y - 10
    a.rect(sx, sy, sw, sh, _c(t, "wood_dark"))
    a.box(sx, sy, sw, sh, _c(t, "line"))
    shelf_h = (sh - 4) // 4
    for i in range(4):
        top = sy + 2 + i * shelf_h
        x = sx + 2
        while x < sx + sw - 4:
            bw = rng.choice((2, 3, 3, 4))
            bh = rng.randint(shelf_h - 7, shelf_h - 3)
            color = rgb(rng.choice(t["books"]))
            a.rect(x, top + shelf_h - 2 - bh, bw, bh, color)
            a.vline(x + bw - 1, top + shelf_h - 2 - bh, bh, shade(color, 0.75))
            if bw >= 3:
                a.hline(x, top + shelf_h - 2 - bh + 2, bw - 1, shade(color, 1.25))
            x += bw + (1 if rng.random() < 0.25 else 0)
        a.rect(sx + 1, top + shelf_h - 2, sw - 2, 2, _c(t, "wood_light"))

    # 바닥 널
    a.rect(0, floor_y, w, h - floor_y, _c(t, "floor"))
    a.hline(0, floor_y, w, _c(t, "line"))
    row = 0
    for y in range(floor_y + 4, h, 5):
        a.hline(0, y, w, _c(t, "floor_dark"))
        offset = (row * 13) % 29
        for x in range(offset, w, 29):
            a.vline(x, y - 4, 4, _c(t, "floor_dark"))
        a.hline(0, y + 1, w, _c(t, "floor_light")) if row % 2 == 0 else None
        row += 1

    # 러그
    rx, rw = int(w * 0.26), int(w * 0.48)
    ry, rh = floor_y + 10, min(22, h - floor_y - 12)
    if rh > 6:
        a.rect(rx, ry, rw, rh, _c(t, "rug"))
        a.box(rx, ry, rw, rh, _c(t, "rug_dark"))
        a.box(rx + 2, ry + 2, rw - 4, rh - 4, _c(t, "rug_trim"))

    # 창에서 들어오는 빛(디더)
    beam = _c(t, "beam")
    for i in range(0, 26):
        y = floor_y + 2 + i // 2
        if y >= h:
            break
        a.dither(wx - 6 + i, y, ww - 8, 1, (beam[0], beam[1], beam[2], 90), phase=i)

    # 책상(오른쪽 앞)
    dx, dw = int(w * 0.70), int(w * 0.28)
    dy = floor_y - 8
    a.rect(dx, dy, dw, 4, _c(t, "wood_light"))
    a.hline(dx, dy + 4, dw, _c(t, "wood_dark"))
    a.rect(dx + 2, dy + 5, 3, 16, _c(t, "wood_dark"))
    a.rect(dx + dw - 5, dy + 5, 3, 16, _c(t, "wood_dark"))
    # 책상 위 책 더미와 촛대
    a.rect(dx + 4, dy - 4, 10, 4, rgb(t["books"][0]))
    a.rect(dx + 5, dy - 7, 9, 3, rgb(t["books"][1]))
    a.rect(dx + dw - 9, dy - 9, 2, 9, _c(t, "banner_trim"))
    a.px(dx + dw - 9, dy - 11, rgb("ffd27a"))
    a.px(dx + dw - 8, dy - 10, rgb("fff3c0"))
    return a


def library(w: int, h: int, theme_name: str = "warm", seed: int = 11) -> Art:
    """양쪽 벽이 책장인 도서관. 학습 활동 배경."""
    t = THEMES[theme_name]
    a = study_room(w, h, theme_name, seed)
    rng = seeded(seed + 1)
    floor_y = int(h * 0.68)
    sx, sw = w - 4 - int(w * 0.26), int(w * 0.26)
    sy, sh = 10, floor_y - 10
    a.rect(sx, sy, sw, sh, _c(t, "wood_dark"))
    a.box(sx, sy, sw, sh, _c(t, "line"))
    shelf_h = (sh - 4) // 4
    for i in range(4):
        top = sy + 2 + i * shelf_h
        x = sx + 2
        while x < sx + sw - 4:
            bw = rng.choice((2, 3, 3, 4))
            bh = rng.randint(shelf_h - 7, shelf_h - 3)
            color = rgb(rng.choice(t["books"]))
            a.rect(x, top + shelf_h - 2 - bh, bw, bh, color)
            a.vline(x + bw - 1, top + shelf_h - 2 - bh, bh, shade(color, 0.75))
            x += bw + (1 if rng.random() < 0.25 else 0)
        a.rect(sx + 1, top + shelf_h - 2, sw - 2, 2, _c(t, "wood_light"))
    # 독서대와 펼친 책
    lx = int(w * 0.40)
    a.rect(lx, floor_y - 14, 26, 3, _c(t, "wood_light"))
    a.rect(lx + 11, floor_y - 11, 4, 18, _c(t, "wood_dark"))
    a.rect(lx + 2, floor_y - 18, 10, 4, rgb("f6efe0"))
    a.rect(lx + 14, floor_y - 18, 10, 4, rgb("f6efe0"))
    a.vline(lx + 13, floor_y - 18, 4, _c(t, "line"))
    return a


def city(w: int, h: int, seed: int = 21) -> Art:
    """왕도 거리. 아르바이트·산책 배경."""
    rng = seeded(seed)
    a = Art(w, h, rgb("8fc8f0"))
    horizon = int(h * 0.66)
    for y in range(0, 30, 6):
        a.hline(0, y, w, rgb("a6d4f4"))
    for cx, cy in ((30, 14), (120, 22)):
        a.ellipse(cx, cy, cx + 26, cy + 8, rgb("f4fbff"))
        a.ellipse(cx + 8, cy - 4, cx + 22, cy + 6, rgb("f4fbff"))
    x = -4
    palette = ["d9a77a", "c9806a", "e8cfa0", "a8b88a", "c4a0c0", "9ab0d0"]
    while x < w:
        bw = rng.randint(26, 40)
        top = rng.randint(28, 52)
        wall = rgb(rng.choice(palette))
        a.rect(x, top, bw, horizon - top, wall)
        a.box(x, top, bw, horizon - top, shade(wall, 0.5))
        # 지붕
        roof = rgb(rng.choice(["8a3a3a", "4a5a8a", "5a7a4a"]))
        a.poly([(x - 2, top), (x + bw + 1, top), (x + bw // 2, top - 10)], roof)
        for wy in range(top + 8, horizon - 14, 14):
            for wx in range(x + 5, x + bw - 6, 10):
                a.rect(wx, wy, 5, 7, rgb("5a4a6a"))
                a.rect(wx + 1, wy + 1, 3, 3, rgb("ffe8a0") if rng.random() < 0.35 else rgb("8ab4dc"))
        door_x = x + bw // 2 - 3
        a.rect(door_x, horizon - 12, 7, 12, shade(wall, 0.45))
        x += bw + 1
    # 차양
    a.rect(int(w * 0.55), horizon - 20, 34, 5, rgb("c84a4a"))
    for i in range(0, 34, 4):
        a.rect(int(w * 0.55) + i, horizon - 20, 2, 5, rgb("fff4e6"))
    # 돌길
    a.rect(0, horizon, w, h - horizon, rgb("b8a890"))
    a.hline(0, horizon, w, rgb("6a5a4a"))
    for y in range(horizon + 3, h, 6):
        off = (y // 6 % 2) * 6
        for xx in range(-off, w, 12):
            a.box(xx, y, 11, 6, rgb("9a8a74"))
    # 가로등
    a.rect(int(w * 0.18), horizon - 46, 3, 46, rgb("3a3a48"))
    a.rect(int(w * 0.18) - 3, horizon - 52, 9, 7, rgb("3a3a48"))
    a.rect(int(w * 0.18) - 2, horizon - 51, 7, 5, rgb("ffe08a"))
    return a


def forest(w: int, h: int, seed: int = 31) -> Art:
    """별빛 숲. 모험·여행 배경."""
    rng = seeded(seed)
    a = Art(w, h, rgb("a8dcc8"))
    ground = int(h * 0.70)
    for y in range(0, 40, 5):
        a.hline(0, y, w, rgb("c4ead6"))
    layers = [(rgb("6aa88a"), 40, 0.55), (rgb("3e7a5e"), 30, 0.62), (rgb("2a5a44"), 22, 0.68)]
    for color, size, base in layers:
        x = -size // 2
        while x < w + size:
            top = int(h * base) - rng.randint(size, size * 2)
            a.ellipse(x, top, x + size, int(h * base) + 6, color)
            a.rect(x + size // 2 - 2, int(h * base) - 2, 4, ground - int(h * base) + 4, shade(color, 0.6))
            x += size - rng.randint(4, 10)
    a.rect(0, ground, w, h - ground, rgb("5a9a4a"))
    a.hline(0, ground, w, rgb("3a6a30"))
    for y in range(ground + 4, h, 5):
        for xx in range(rng.randint(0, 6), w, rng.randint(8, 14)):
            a.px(xx, y, rgb("7aba5a"))
            a.px(xx + 1, y - 1, rgb("7aba5a"))
    # 오솔길
    a.poly([(w // 2 - 12, ground), (w // 2 + 12, ground), (w // 2 + 40, h), (w // 2 - 40, h)], rgb("c8a878"))
    # 꽃과 버섯
    for fx, fy, col in ((20, ground + 12, "f4a0c0"), (160, ground + 18, "fff0a0"), (40, ground + 30, "a0c8ff"), (176, ground + 34, "f4a0c0")):
        a.rect(fx, fy, 2, 2, rgb(col))
    a.rect(140, ground + 6, 6, 3, rgb("d84a4a"))
    a.px(141, ground + 6, rgb("ffffff"))
    a.rect(142, ground + 9, 2, 3, rgb("f4e8d0"))
    # 빛줄기(디더)
    for i in range(0, 30):
        a.dither(60 + i, 10 + i * 2, 10, 2, (255, 250, 210, 70), phase=i)
    return a


def arena(w: int, h: int, seed: int = 41) -> Art:
    """시험·대회 경기장."""
    rng = seeded(seed)
    a = Art(w, h, rgb("9ccbf0"))
    stands_top, stands_bottom = 24, int(h * 0.56)
    a.rect(0, stands_top, w, stands_bottom - stands_top, rgb("8a6a5a"))
    for y in range(stands_top + 4, stands_bottom - 4, 7):
        a.hline(0, y + 5, w, rgb("6a4a3e"))
        for x in range(2, w, 4):
            color = rgb(rng.choice(["f4c8a0", "d8a078", "a87050", "f0d8b8"]))
            a.rect(x, y + 1, 2, 2, color)
            a.rect(x, y + 3, 2, 2, rgb(rng.choice(["c84a4a", "4a6ac8", "e8b84a", "5aa86a", "f4f0e8"])))
    # 깃발
    for fx in range(10, w, 36):
        a.vline(fx, 6, 20, rgb("5a4a3a"))
        a.poly([(fx + 1, 6), (fx + 14, 10), (fx + 1, 14)], rgb(rng.choice(["c84a4a", "4a6ac8", "e8b84a"])))
    a.rect(0, stands_bottom, w, 6, rgb("5a3a2a"))
    a.hline(0, stands_bottom, w, rgb("e8b84a"))
    a.rect(0, stands_bottom + 6, w, h - stands_bottom - 6, rgb("e0c08a"))
    for y in range(stands_bottom + 10, h, 6):
        for x in range((y // 6 % 3) * 5, w, 15):
            a.px(x, y, rgb("c8a470"))
    a.ellipse(w // 2 - 50, stands_bottom + 20, w // 2 + 50, h - 6, rgb("d4b07a"))
    a.ellipse(w // 2 - 46, stands_bottom + 23, w // 2 + 46, h - 9, rgb("e0c08a"))
    return a


ENVIRONMENTS = {
    "academy": lambda w, h: study_room(w, h, "warm"),
    "library": lambda w, h: library(w, h, "warm"),
    "city": city,
    "forest": forest,
    "arena": arena,
}
