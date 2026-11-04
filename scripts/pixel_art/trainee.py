"""수련생 도트 페이퍼돌.

캔버스 40×54 아트픽셀(논리 80×108). 몸 기준 레이어는 (4, 2)에 놓이고, 장비 레이어는 같은 캔버스를 쓴다.
모든 레이어는 '균형' 팔레트로 그리고, 성장 분야별 제복 색은 recolor_map()의 색 치환으로 바꾼다.
Godot TraineeCompositor가 generate.py가 쓴 JSON을 읽어 같은 순서로 합성한다.
"""
from __future__ import annotations

from pixellib import Art, rgb, selective_outline, shade

W, H = 40, 54
OX, OY = 4, 2  # 32×52 몸 좌표를 캔버스에 놓는 위치

BASE_PALETTE = {
    "skin": rgb("f7d6bc"), "skin_shade": rgb("e2aa8c"), "skin_line": rgb("a9675a"),
    "hair": rgb("8a5232"), "hair_shade": rgb("5e3420"), "hair_light": rgb("b8774a"), "hair_line": rgb("33190f"),
    "eye": rgb("2b1d24"), "iris": rgb("4f6fc4"), "iris_dark": rgb("33468c"), "white": rgb("fffaf2"),
    "blush": rgb("f19c9c"), "mouth": rgb("b8525a"),
    "blouse": rgb("f6f1e7"), "blouse_shade": rgb("cfc6b8"),
    "ribbon": rgb("d0465a"), "ribbon_shade": rgb("9a2e40"),
    "cloth": rgb("344079"), "cloth_shade": rgb("222a55"), "cloth_light": rgb("4d5c9e"),
    "trim": rgb("e9b949"), "trim_shade": rgb("a87a2a"),
    "stocking": rgb("3b2f45"), "boot": rgb("6b4330"), "boot_shade": rgb("45291d"),
    "steel": rgb("c8d0dc"), "steel_shade": rgb("8a94a8"), "steel_light": rgb("f2f6fb"),
    "leather": rgb("8a5a36"), "leather_shade": rgb("5e3a22"),
    "robe": rgb("2a2f5e"), "robe_shade": rgb("1a1e40"), "star": rgb("ffe9a0"),
    "wood": rgb("9a6a3e"), "gem": rgb("7fd8ff"), "gem_shade": rgb("3a8ac0"), "frill": rgb("ffd6e4"),
}

# 성장 분야별 제복 색(기본, 그림자, 밝은 면). 같은 실루엣에서 색만 바꾼다.
OUTFIT_COLORS = {
    "balanced": ("344079", "222a55", "4d5c9e"),
    "scholar": ("2f5a8a", "1d3a5e", "4a7cb0"),
    "martial": ("8a3434", "5e2020", "b04a4a"),
    "artist": ("7a3a7a", "52244f", "a05aa0"),
    "leader": ("2f6a5a", "1d4a3e", "4a8c7a"),
    "care": ("b07c88", "86566a", "d0a0aa"),
    "explorer": ("5a6a2f", "3e4a1d", "7a8c4a"),
    "prosperity": ("8a6a2a", "5e481a", "b08c3e"),
}
CLOTH_ROLES = ("cloth", "cloth_shade", "cloth_light")
LINE_FACTOR = 0.42

OUTFITS = ("OUTFIT_PLAIN", "OUTFIT_FORMAL", "OUTFIT_NOBLE", "OUTFIT_ACTIVE", "OUTFIT_STAGE")
ARMORS = ("ARM_LEATHER", "ARM_PLATE", "ARM_ROBE")
WEAPONS = ("WPN_DAGGER", "WPN_SWORD", "WPN_RAPIER", "WPN_WAND")
ACCESSORIES = ("ACC_RIBBON", "ACC_JEWEL")
EXPRESSIONS = ("smile", "focus")


def palette_for(preset: str = "balanced") -> dict:
    pal = dict(BASE_PALETTE)
    base, dark, light = OUTFIT_COLORS.get(preset, OUTFIT_COLORS["balanced"])
    pal["cloth"], pal["cloth_shade"], pal["cloth_light"] = rgb(base), rgb(dark), rgb(light)
    return pal


def recolor_map(preset: str) -> dict:
    """균형 팔레트 색 → 해당 분야 색. 외곽선(어두운 단계)도 함께 바꾼다."""
    src, dst = palette_for("balanced"), palette_for(preset)
    mapping = {}
    for role in CLOTH_ROLES:
        mapping[src[role]] = dst[role]
        mapping[shade(src[role], LINE_FACTOR)] = shade(dst[role], LINE_FACTOR)
    return {k: v for k, v in mapping.items() if k != v}


def _outline(pal: dict):
    table = {
        pal["hair"]: pal["hair_line"], pal["hair_shade"]: pal["hair_line"], pal["hair_light"]: pal["hair_line"],
        pal["skin"]: pal["skin_line"], pal["skin_shade"]: pal["skin_line"],
    }
    return lambda color: table.get(color, shade(color, LINE_FACTOR))


def _body_art() -> Art:
    return Art(32, 52)


def _place(body_art: Art, pal: dict, outline: bool = True) -> Art:
    if outline:
        selective_outline(body_art, _outline(pal))
    canvas = Art(W, H)
    canvas.blit(body_art, OX, OY)
    return canvas


def hair_back(pal: dict) -> Art:
    a = _body_art()
    a.ellipse(6, 1, 25, 19, pal["hair"])
    a.rect(6, 12, 4, 20, pal["hair"])
    a.rect(22, 12, 4, 20, pal["hair"])
    a.poly([(6, 31), (9, 31), (8, 35)], pal["hair"])
    a.poly([(22, 31), (25, 31), (23, 35)], pal["hair"])
    for y in range(12, 34):
        a.px(24, y, pal["hair_shade"])
        a.px(25, y, pal["hair_shade"])
        a.px(7, y, pal["hair_shade"])
    return _place(a, pal)


def body(pal: dict) -> Art:
    a = _body_art()
    a.ellipse(9, 5, 22, 19, pal["skin"])
    a.rect(10, 15, 12, 3, pal["skin"])
    for y in range(8, 18):
        a.px(21, y, pal["skin_shade"])
    a.rect(14, 19, 4, 3, pal["skin_shade"])
    a.rect(7, 34, 3, 2, pal["skin"])
    a.rect(22, 34, 3, 2, pal["skin"])
    # 다리는 치마 속까지 그려 짧은 치마에서도 비지 않게 한다
    a.rect(12, 36, 3, 12, pal["stocking"])
    a.rect(17, 36, 3, 12, pal["stocking"])
    a.rect(11, 47, 4, 4, pal["boot"])
    a.rect(17, 47, 4, 4, pal["boot"])
    a.hline(11, 50, 4, pal["boot_shade"])
    a.hline(17, 50, 4, pal["boot_shade"])
    return _place(a, pal)


def _uniform_base(a: Art, pal: dict, skirt_bottom: int = 44) -> None:
    c, cs, cl = pal["cloth"], pal["cloth_shade"], pal["cloth_light"]
    a.poly([(9, 23), (12, 23), (11, 34), (7, 34)], c)
    a.poly([(19, 23), (22, 23), (24, 34), (20, 34)], c)
    a.vline(23, 27, 7, cs)
    a.hline(7, 33, 5, pal["blouse"])
    a.hline(20, 33, 5, pal["blouse"])
    a.poly([(11, 21), (20, 21), (19, 32), (12, 32)], c)
    a.vline(19, 24, 8, cs)
    a.hline(12, 32, 8, cs)
    spread = (skirt_bottom - 33) * 6 // 11
    a.poly([(12, 33), (19, 33), (19 + spread, skirt_bottom), (12 - spread, skirt_bottom)], c)
    for top, bottom in ((13, 12 - spread + 3), (15, 14), (17, 17), (18, 19 + spread - 3)):
        a.d.line([(top, 35), (bottom, skirt_bottom - 1)], fill=cs)
    for x in range(19, 19 + spread):
        a.px(x, skirt_bottom - 1, cs)
    a.poly([(13, 20), (18, 20), (16, 25), (15, 25)], pal["blouse"])
    a.px(13, 21, pal["blouse_shade"])
    a.px(18, 21, pal["blouse_shade"])


def _capelet(a: Art, pal: dict, trim: bool) -> None:
    c, cs, cl = pal["cloth"], pal["cloth_shade"], pal["cloth_light"]
    a.poly([(12, 20), (19, 20), (25, 25), (24, 27), (19, 29), (12, 29), (7, 27), (6, 25)], c)
    a.hline(10, 21, 11, cl)
    a.hline(8, 23, 4, cl)
    edge = ((6, 25), (7, 26), (8, 27), (9, 27), (10, 28), (11, 28), (12, 29), (13, 29), (14, 29), (15, 29),
            (16, 29), (17, 29), (18, 29), (19, 29), (20, 28), (21, 28), (22, 27), (23, 27), (24, 26), (25, 25))
    for x, y in edge:
        a.px(x, y, pal["trim"] if trim else cs)
    for x in range(20, 25):
        a.px(x, 25, cs)
    a.poly([(13, 20), (18, 20), (16, 25), (15, 25)], pal["blouse"])


def _collar_ribbon(a: Art, pal: dict) -> None:
    a.rect(14, 22, 4, 2, pal["ribbon"])
    a.px(13, 22, pal["ribbon"])
    a.px(18, 22, pal["ribbon"])
    a.px(15, 24, pal["ribbon_shade"])
    a.px(16, 24, pal["ribbon_shade"])


def outfit(pal: dict, item: str) -> Art:
    a = _body_art()
    if item == "OUTFIT_ACTIVE":
        _uniform_base(a, pal, skirt_bottom=40)
        a.hline(11, 31, 10, pal["leather"])
        a.px(15, 31, pal["trim"])
        a.px(16, 31, pal["trim"])
        a.hline(9, 40, 14, pal["cloth_shade"])
        _collar_ribbon(a, pal)
        return _place(a, pal)
    _uniform_base(a, pal)
    a.hline(6, 44, 20, pal["trim"] if item != "OUTFIT_PLAIN" else pal["cloth_shade"])
    a.hline(7, 45, 18, pal["trim_shade"] if item != "OUTFIT_PLAIN" else pal["cloth_shade"])
    if item == "OUTFIT_PLAIN":
        _collar_ribbon(a, pal)
        return _place(a, pal)
    _capelet(a, pal, trim=True)
    _collar_ribbon(a, pal)
    a.px(15, 27, pal["trim"])
    a.px(16, 27, pal["trim"])
    if item == "OUTFIT_NOBLE":
        # 금실 어깨띠와 견장
        for i in range(9):
            a.px(10 + i, 30 + i // 3, pal["trim"])
        a.rect(6, 24, 3, 2, pal["trim"])
        a.rect(23, 24, 3, 2, pal["trim"])
        a.hline(7, 42, 18, pal["trim"])
    elif item == "OUTFIT_STAGE":
        # 별빛 무대 의상: 치마에 별, 밑단 프릴
        for x, y in ((10, 38), (15, 36), (20, 39), (13, 41), (18, 42), (8, 42)):
            a.px(x, y, pal["star"])
        for x in range(6, 26, 2):
            a.px(x, 45, pal["frill"])
            a.px(x + 1, 46, pal["frill"])
    return _place(a, pal)


def armor(pal: dict, item: str) -> Art:
    a = _body_art()
    if item == "ARM_LEATHER":
        a.rect(6, 23, 5, 4, pal["leather"])
        a.rect(21, 23, 5, 4, pal["leather"])
        a.hline(6, 23, 5, pal["leather_shade"])
        a.hline(21, 23, 5, pal["leather_shade"])
        for i in range(10):
            a.px(11 + i, 24 + i, pal["leather"])
            a.px(11 + i, 25 + i, pal["leather_shade"])
    elif item == "ARM_PLATE":
        a.poly([(11, 22), (20, 22), (20, 31), (15, 33), (11, 31)], pal["steel"])
        a.vline(15, 23, 9, pal["steel_light"])
        a.vline(19, 23, 8, pal["steel_shade"])
        a.rect(5, 22, 6, 5, pal["steel"])
        a.rect(21, 22, 6, 5, pal["steel"])
        a.hline(5, 22, 6, pal["steel_light"])
        a.hline(21, 22, 6, pal["steel_light"])
        a.hline(5, 26, 6, pal["steel_shade"])
        a.hline(21, 26, 6, pal["steel_shade"])
    elif item == "ARM_ROBE":
        a.poly([(8, 21), (12, 21), (11, 46), (5, 46)], pal["robe"])
        a.poly([(19, 21), (23, 21), (26, 46), (20, 46)], pal["robe"])
        a.vline(11, 22, 24, pal["robe_shade"])
        a.vline(20, 22, 24, pal["robe_shade"])
        for x, y in ((7, 28), (9, 35), (6, 41), (22, 30), (24, 37), (22, 43)):
            a.px(x, y, pal["star"])
        a.hline(5, 46, 7, pal["trim"])
        a.hline(20, 46, 7, pal["trim"])
    return _place(a, pal)


def weapon(pal: dict, item: str) -> Art:
    """오른손(화면 오른쪽) 옆에 세운 무기. 캔버스 좌표로 그린다."""
    a = Art(W, H)
    if item == "WPN_DAGGER":
        a.rect(30, 33, 3, 8, pal["steel_light"])
        a.vline(32, 34, 6, pal["steel_shade"])
        a.hline(29, 41, 6, pal["trim"])
        a.rect(31, 42, 2, 3, pal["leather"])
    elif item == "WPN_SWORD":
        a.rect(31, 12, 4, 26, pal["steel"])
        a.vline(32, 12, 26, pal["steel_light"])
        a.vline(33, 13, 24, pal["steel_shade"])
        a.rect(32, 10, 2, 2, pal["steel"])
        a.hline(29, 38, 8, pal["trim"])
        a.rect(32, 39, 2, 5, pal["leather"])
        a.rect(32, 44, 2, 2, pal["trim"])
    elif item == "WPN_RAPIER":
        a.rect(32, 10, 3, 29, pal["steel_light"])
        a.vline(34, 12, 26, pal["steel_shade"])
        a.box(30, 38, 7, 3, pal["trim"])
        a.rect(33, 41, 2, 4, pal["leather"])
    elif item == "WPN_WAND":
        a.rect(33, 16, 2, 34, pal["wood"])
        a.vline(34, 17, 32, pal["leather_shade"])
        a.box(31, 10, 6, 6, pal["trim"])
        a.rect(32, 11, 4, 4, pal["gem"])
        a.px(33, 12, pal["white"])
        a.px(35, 14, pal["gem_shade"])
    selective_outline(a, _outline(pal))
    return a


def face(pal: dict, expression: str = "smile") -> Art:
    a = _body_art()
    for ex in (11, 19):
        a.hline(ex - 1, 11, 3, pal["eye"])
        a.px(ex, 12, pal["iris"])
        a.px(ex + 1, 12, pal["white"])
        a.px(ex, 13, pal["iris_dark"])
        a.px(ex + 1, 13, pal["iris"])
    a.hline(10, 15, 2, pal["blush"])
    a.hline(20, 15, 2, pal["blush"])
    if expression == "smile":
        a.px(15, 16, pal["mouth"])
        a.px(16, 16, pal["mouth"])
        a.px(14, 15, pal["skin_shade"])
        a.px(17, 15, pal["skin_shade"])
    else:
        a.hline(15, 16, 2, pal["skin_line"])
    return _place(a, pal, outline=False)


def hair_front(pal: dict) -> Art:
    a = _body_art()
    h, hs, hl = pal["hair"], pal["hair_shade"], pal["hair_light"]
    a.ellipse(8, 2, 23, 14, h)
    cut = [10, 9, 10, 11, 10, 9, 9, 10, 11, 10, 9, 10, 11, 10, 10]
    for i, x in enumerate(range(9, 24)):
        for y in range(cut[i], 15):
            a.px(x, y, (0, 0, 0, 0))
    a.rect(8, 9, 3, 9, h)
    a.rect(21, 9, 3, 9, h)
    a.px(8, 18, h)
    a.px(23, 18, h)
    for x, y in ((11, 4), (12, 4), (13, 3), (14, 3), (15, 3), (12, 5), (10, 5)):
        a.px(x, y, hl)
    for y in range(9, 18):
        a.px(22, y, hs)
    for x in (12, 16, 19):
        a.px(x, 9, hs)
    return _place(a, pal)


def accessory(pal: dict, item: str) -> Art:
    a = _body_art()
    if item == "ACC_RIBBON":
        a.rect(19, 2, 4, 3, pal["ribbon"])
        for x in (18, 21, 23):
            a.px(x, 3, pal["ribbon_shade"])
        return _place(a, pal)
    if item == "ACC_JEWEL":
        a.rect(14, 25, 4, 3, pal["trim"])
        a.rect(15, 25, 2, 2, pal["gem"])
        a.px(15, 25, pal["white"])
        a.px(16, 27, pal["gem_shade"])
    return _place(a, pal)


def layers(preset: str = "balanced") -> dict[str, Art]:
    """이름 → 레이어. 합성 순서는 ORDER를 따른다."""
    pal = palette_for(preset)
    result = {"hair_back": hair_back(pal), "body": body(pal), "hair_front": hair_front(pal)}
    for item in OUTFITS:
        result[f"outfit:{item}"] = outfit(pal, item)
    for item in ARMORS:
        result[f"armor:{item}"] = armor(pal, item)
    for item in WEAPONS:
        result[f"weapon:{item}"] = weapon(pal, item)
    for item in ACCESSORIES:
        result[f"accessory:{item}"] = accessory(pal, item)
    for expression in EXPRESSIONS:
        result[f"face:{expression}"] = face(pal, expression)
    return result


ORDER = ("hair_back", "body", "outfit", "armor", "face", "hair_front", "accessory", "weapon")


def compose(preset: str = "balanced", equipment: dict | None = None, expression: str = "smile") -> Art:
    equipment = equipment or {}
    all_layers = layers(preset)
    out = Art(W, H)
    for slot in ORDER:
        if slot in ("hair_back", "body", "hair_front"):
            key = slot
        elif slot == "face":
            key = f"face:{expression}"
        elif slot == "outfit":
            key = f"outfit:{equipment.get('outfit') or 'OUTFIT_PLAIN'}"
        else:
            item = equipment.get(slot)
            if not item:
                continue
            key = f"{slot}:{item}"
        out.blit(all_layers[key], 0, 0)
    return out


def portrait(preset: str = "balanced", size: int = 24) -> Art:
    full = compose(preset, {"outfit": "OUTFIT_FORMAL", "accessory": "ACC_RIBBON"})
    crop = full.img.crop((20 - size // 2, OY, 20 + size // 2, OY + size))
    a = Art(size, size)
    a.blit(crop, 0, 0)
    return a
