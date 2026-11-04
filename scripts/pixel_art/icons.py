"""도트 아이콘 픽셀맵. 행 문자열의 각 글자는 ICON_PALETTE 키이고 '.'은 투명이다."""
from __future__ import annotations

from pixellib import Art, from_rows, rgb

ICON_PALETTE = {
    "k": rgb("231a2a"),  # 외곽선
    "w": rgb("fffaf0"),
    "y": rgb("f4c542"), "Y": rgb("b8862a"), "o": rgb("fff0a8"),
    "r": rgb("e0524f"), "R": rgb("9e2f3a"),
    "b": rgb("5b8ee6"), "B": rgb("34569e"), "c": rgb("9fd8ff"),
    "g": rgb("5cc06b"), "G": rgb("2f7a45"),
    "p": rgb("b07ae0"), "P": rgb("6e44a0"),
    "n": rgb("8a5a36"), "N": rgb("5a3820"), "t": rgb("e9d3a6"), "T": rgb("c7a97a"),
    "s": rgb("9aa3b8"), "S": rgb("5e6680"),
}

ICONS: dict[str, list[str]] = {
    "coin": [
        "..kkkk..",
        ".kyyyyk.",
        "kyoyyyYk",
        "kyoYYyYk",
        "kyoYYyYk",
        "kyyyyyYk",
        ".kYYYYk.",
        "..kkkk..",
    ],
    "energy": [
        "....kkk.",
        "...kyyk.",
        "..kyyk..",
        ".kyyyyk.",
        ".kkkyyk.",
        "...kyk..",
        "..kyk...",
        "..kk....",
    ],
    "stress": [
        "..kkkk..",
        ".krrrrk.",
        "krrwrrRk",
        "krwrrrRk",
        "krrrrrRk",
        ".kRrrRk.",
        "..kRRk..",
        "...kk...",
    ],
    "reputation": [
        "...kk...",
        "...ky...",
        "kkkyykkk",
        "kyyyoyyk",
        ".kyyyyk.",
        ".kyykyk.",
        "kyk..kyk",
        "kk....kk",
    ],
    "menu": [
        "kkkkkkkk",
        "kwwwwwwk",
        "kkkkkkkk",
        "........",
        "kkkkkkkk",
        "kwwwwwwk",
        "kkkkkkkk",
        "........",
    ],
    "pause": [
        "kkk..kkk",
        "kwk..kwk",
        "kwk..kwk",
        "kwk..kwk",
        "kwk..kwk",
        "kwk..kwk",
        "kwk..kwk",
        "kkk..kkk",
    ],
    "play": [
        "kk......",
        "kwkk....",
        "kwwwkk..",
        "kwwwwwkk",
        "kwwwwwkk",
        "kwwwkk..",
        "kwkk....",
        "kk......",
    ],
    "magic": [
        ".........k..",
        "........kok.",
        ".kkkkkkkkk..",
        "kPpppppppPk.",
        "kPppyyyppPk.",
        "kPpyoooypPk.",
        "kPppyyyppPk.",
        "kPpppppppPk.",
        "kPPPPPPPPPk.",
        "kwtwtwtwtwk.",
        "kkkkkkkkkkk.",
        "............",
    ],
    "home": [
        ".....kk.....",
        "....kRRk....",
        "...kRrrRk...",
        "..kRrrrrRk..",
        ".kRrrrrrrRk.",
        "kkkkkkkkkkkk",
        ".ktttttttTk.",
        ".ktkkttkkTk.",
        ".ktkbtnnkTk.",
        ".ktkktknkTk.",
        ".ktttTknkTk.",
        ".kkkkkkkkkk.",
    ],
    "plan": [
        ".kkkkkkkkk..",
        "kTttttttttk.",
        "kTtkkkkkttk.",
        ".ktttttttTk.",
        ".ktkkkkktTk.",
        ".ktttttttTk.",
        ".ktkkkkttTk.",
        ".ktttttttTk.",
        ".ktkkkkktTk.",
        "kTtttttttttk",
        "kTTTTTTTTTTk",
        ".kkkkkkkkkk.",
    ],
    "activity": [
        "..........kk",
        ".........kyk",
        "........kyk.",
        ".kkkkk.kyk..",
        "kBbbbbkkk.kk",
        "kBbwwbkBbbBk",
        "kBbbbbkBbbBk",
        "kBbwwbkBwwBk",
        "kBbbbbkBbbBk",
        "kBbbbbkBbbBk",
        "kBBBBBkBBBBk",
        ".kkkkk.kkkk.",
    ],
    "growth": [
        "........kk..",
        ".......kgGk.",
        "......kggGGk",
        ".....kkkgGkk",
        "....kyk.kgk.",
        "...kyYk.kgk.",
        "kk.kyYkkkgk.",
        "kbkkyYkgkgk.",
        "kbBkyYkgkgk.",
        "kbBkyYkgkgk.",
        "kbBkyYkgkgk.",
        "kkkkkkkkkkk.",
    ],
    "record": [
        ".kkkkkkkkkk.",
        "kyyyyyyyyyYk",
        "kykyyyyyykYk",
        "kykyyoyyykYk",
        ".kkyyyyyYkk.",
        "..kyyyyyYk..",
        "...kyyyYk...",
        "....kyYk....",
        "....kyYk....",
        "...kkyYkk...",
        "..kYYYYYYk..",
        "..kkkkkkkk..",
    ],
    "world": [
        "..k.........",
        "..kkkkkkk...",
        "..krrrrrrk..",
        "..krrwrrrRk.",
        "..krrrrrrRk.",
        "..krrrrrrk..",
        "..kkkkkkk...",
        "..k.........",
        "..k.........",
        ".kNk........",
        "kNnNk.......",
        "kkkkk.......",
    ],
    "event": [
        "kkkkkkkkkkkk",
        "kwkwwwwwwkwk",
        "kwwkwwwwkwwk",
        "kwwwkkkkwwwk",
        "kwwwkrrkwwwk",
        "kwwkwkkwkwwk",
        "kwkwwwwwwkwk",
        "kkwwwwwwwwkk",
        "kkkkkkkkkkkk",
        "............",
        "............",
        "............",
    ],
    "lock": [
        "..kkkk..",
        ".ks..sk.",
        ".ks..sk.",
        "kkkkkkkk",
        "kyyyyyYk",
        "kyykkyYk",
        "kyyyyyYk",
        "kkkkkkkk",
    ],
    "cursor": [
        "kk......",
        "kwk.....",
        "kwwk....",
        "kwwwk...",
        "kwwwk...",
        "kwwk....",
        "kwk.....",
        "kk......",
    ],
    "moon": [
        "..kkk...",
        ".kyyk...",
        "kyyk....",
        "kyyk....",
        "kyyk...k",
        "kyyykkyk",
        ".kyyyyk.",
        "..kkkk..",
    ],
    "potion": [
        "...kk...",
        "..kwwk..",
        "...kk...",
        "..krrk..",
        ".krwrrk.",
        "krrrrrRk",
        "krrrrRRk",
        ".kkkkkk.",
    ],
    "minus": [
        "........",
        "........",
        "kkkkkkkk",
        "kwwwwwwk",
        "kwwwwwwk",
        "kkkkkkkk",
        "........",
        "........",
    ],
    "plus": [
        "..kkkk..",
        "..kwwk..",
        "kkkwwkkk",
        "kwwwwwwk",
        "kwwwwwwk",
        "kkkwwkkk",
        "..kwwk..",
        "..kkkk..",
    ],
    "up": [
        "...kk...",
        "..kgGk..",
        ".kggGGk.",
        "kkkgGkkk",
        "..kgGk..",
        "..kgGk..",
        "..kgGk..",
        "..kkkk..",
    ],
}


def icon(name: str) -> Art:
    return from_rows(ICONS[name], ICON_PALETTE)


# ---- 도형으로 그리는 12×12 아이콘(성장 방향 9종, 장비 칸 4종) ----

def _outlined(draw) -> Art:
    """1~10 안쪽에 도형을 그리고, 실루엣 바깥 1px에 외곽선을 두른다."""
    a = Art(12, 12)
    draw(a)
    src = a.img.copy()
    for y in range(12):
        for x in range(12):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 12 and 0 <= ny < 12 and src.getpixel((nx, ny))[3]:
                    a.px(x, y, ICON_PALETTE["k"])
                    break
    return a


P = ICON_PALETTE


def _balanced(a: Art) -> None:
    a.ellipse(1, 1, 10, 10, P["y"])
    a.rect(6, 1, 5, 5, P["b"])
    a.rect(1, 6, 5, 5, P["g"])
    a.rect(6, 6, 5, 5, P["r"])
    for x, y in ((1, 1), (2, 1), (1, 2), (10, 1), (9, 1), (10, 2), (1, 10), (2, 10), (1, 9), (10, 10), (9, 10), (10, 9)):
        a.px(x, y, (0, 0, 0, 0))


def _sword(a: Art) -> None:
    for i in range(7):
        a.px(3 + i, 7 - i, P["w"])
        a.px(4 + i, 7 - i, P["s"])
    a.rect(2, 7, 4, 1, P["y"])
    a.rect(4, 6, 1, 3, P["y"])
    a.px(2, 9, P["n"])
    a.px(3, 8, P["n"])
    a.px(1, 10, P["Y"])


def _palette(a: Art) -> None:
    a.ellipse(1, 2, 10, 10, P["t"])
    a.ellipse(6, 7, 8, 9, (0, 0, 0, 0))
    for x, y, c in ((3, 4, "r"), (6, 3, "b"), (8, 5, "g"), (3, 7, "y")):
        a.rect(x, y, 2, 2, P[c])


def _crown(a: Art) -> None:
    a.poly([(1, 3), (4, 6), (6, 2), (8, 6), (10, 3), (10, 9), (1, 9)], P["y"])
    a.hline(1, 9, 10, P["Y"])
    a.px(3, 7, P["r"])
    a.px(6, 7, P["b"])
    a.px(8, 7, P["g"])


def _heart(a: Art) -> None:
    a.ellipse(1, 2, 6, 7, P["r"])
    a.ellipse(5, 2, 10, 7, P["r"])
    a.poly([(1, 5), (10, 5), (6, 10), (5, 10)], P["r"])
    a.rect(5, 3, 2, 5, P["w"])
    a.rect(4, 4, 4, 2, P["w"])


def _compass(a: Art) -> None:
    a.ellipse(1, 1, 10, 10, P["t"])
    a.ellipse(2, 2, 9, 9, P["w"])
    a.poly([(5, 2), (6, 2), (6, 6), (5, 6)], P["r"])
    a.poly([(5, 6), (6, 6), (6, 9), (5, 9)], P["S"])
    a.px(5, 5, P["k"])


def _bag(a: Art) -> None:
    a.ellipse(1, 4, 10, 11, P["n"])
    a.rect(4, 1, 4, 3, P["n"])
    a.hline(3, 3, 6, P["N"])
    a.ellipse(4, 6, 7, 9, P["y"])
    a.px(5, 7, P["o"])


def _gear(a: Art) -> None:
    a.ellipse(2, 2, 9, 9, P["s"])
    for x, y in ((5, 0), (5, 10), (0, 5), (10, 5), (6, 0), (6, 10), (0, 6), (10, 6), (1, 1), (10, 1), (1, 10), (10, 10)):
        a.px(x, y, P["s"])
    a.ellipse(4, 4, 7, 7, P["S"])
    a.rect(5, 5, 2, 2, (0, 0, 0, 0))


def _dress(a: Art) -> None:
    a.poly([(4, 1), (7, 1), (8, 3), (7, 5), (10, 10), (1, 10), (4, 5), (3, 3)], P["b"])
    a.vline(5, 2, 8, P["B"])
    a.hline(2, 10, 8, P["y"])
    a.px(5, 2, P["w"])
    a.px(6, 2, P["w"])


def _shield(a: Art) -> None:
    a.poly([(1, 1), (10, 1), (10, 6), (6, 10), (5, 10), (1, 6)], P["s"])
    a.vline(5, 2, 8, P["w"])
    a.hline(2, 4, 8, P["w"])
    a.vline(9, 2, 4, P["S"])


def _ring(a: Art) -> None:
    a.ellipse(1, 3, 10, 11, P["y"])
    a.ellipse(3, 5, 8, 9, (0, 0, 0, 0))
    a.rect(4, 1, 4, 3, P["c"])
    a.px(4, 1, P["w"])


SHAPE_ICONS = {
    "preset_balanced": _balanced, "preset_martial": _sword, "preset_artist": _palette, "preset_leader": _crown,
    "preset_care": _heart, "preset_explorer": _compass, "preset_prosperity": _bag, "preset_custom": _gear,
    "slot_outfit": _dress, "slot_weapon": _sword, "slot_armor": _shield, "slot_accessory": _ring,
}


def all_icon_names() -> list[str]:
    return list(ICONS) + list(SHAPE_ICONS)


def any_icon(name: str) -> Art:
    if name in SHAPE_ICONS:
        return _outlined(SHAPE_ICONS[name])
    return icon(name)
