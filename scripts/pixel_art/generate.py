"""게임 런타임 도트 에셋 생성기(방향 A. 아카데미 방).

    python3 scripts/pixel_art/generate.py          # godot/assets/pixel/ 갱신
    python3 scripts/pixel_art/generate.py --check  # 다시 생성해 커밋본과 픽셀 단위 비교

출력
- ui/*.png, ui/skins.json : 2배로 키운 9분할 스킨과 계약(크기, 분할, 내용 여백, 최소 크기, 상태)
- icons/*.png             : 1배 아이콘(화면에서 2배로 그린다)
- scenes/*.png            : 1배 배경 5종
- sprites/trainee.json    : 페이퍼돌 레이어(팔레트 키 행)와 성장 분야별 색 치환
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys
import tempfile

from PIL import Image, ImageChops

import icons as icon_maps
import scenes
import trainee
from pixellib import ROOT, SCALE, Art, rgb, shade
from ui_kit import bubble as ui_bubble

OUT = ROOT / "godot" / "assets" / "pixel"
CONTRACT_DOC = ROOT / "docs" / "game-design" / "ui" / "skin-contract.md"
SCENE_SIZE = (195, 200)

PALETTES = {
    "": {  # 기본: 호두나무와 양피지
        "outline": rgb("2e1a0e"), "panel": rgb("f2e2bc"), "panel_hi": rgb("fff4d6"), "panel_lo": rgb("d6bd8e"),
        "border": rgb("8a5a34"), "inset": rgb("fbf0d2"), "inset_border": rgb("c9a878"),
        "gold_border": rgb("d39a2a"), "accent_border": rgb("a8463a"),
        "strip": rgb("6a4024"), "strip_hi": rgb("8e5a34"), "strip_lo": rgb("4a2a16"),
        "primary": rgb("2f7040"), "gold": rgb("e3b54a"), "secondary": rgb("e8d4a8"), "danger": rgb("b8483e"),
        "disabled": rgb("c8b898"), "chip": rgb("e6cf9e"), "focus": rgb("2e5a9a"), "gauge_bg": rgb("4a2e1c"),
        "selected": rgb("fff0b8"), "toast": rgb("4a2a16"),
    },
    "_hc": {  # 고대비: 검정 외곽선, 흰 면, 진한 행동색
        "outline": rgb("000000"), "panel": rgb("ffffff"), "panel_hi": rgb("ffffff"), "panel_lo": rgb("dddddd"),
        "border": rgb("000000"), "inset": rgb("ffffff"), "inset_border": rgb("000000"),
        "gold_border": rgb("000000"), "accent_border": rgb("000000"),
        "strip": rgb("000000"), "strip_hi": rgb("333333"), "strip_lo": rgb("000000"),
        "primary": rgb("00501a"), "gold": rgb("ffd400"), "secondary": rgb("ffffff"), "danger": rgb("a00000"),
        "disabled": rgb("bbbbbb"), "chip": rgb("ffffff"), "focus": rgb("0040ff"), "gauge_bg": rgb("000000"),
        "selected": rgb("fff27a"), "toast": rgb("000000"),
    },
}

GAUGE_COLORS = {
    "energy": rgb("5cc06b"), "stress": rgb("e0605a"), "reputation": rgb("f0be3c"),
    "stat": rgb("6aa0f0"), "magic": rgb("b07ae0"), "neutral": rgb("c8a060"),
}


def _cut(a: Art, w: int, h: int) -> None:
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        a.px(x, y, (0, 0, 0, 0))


def window(p: dict, border_key: str = "border", fill_key: str = "panel") -> Art:
    a = Art(12, 12)
    a.rect(0, 0, 12, 12, p["outline"])
    a.rect(1, 1, 10, 10, p[border_key])
    a.rect(2, 2, 8, 8, p[fill_key])
    a.hline(2, 2, 8, p["panel_hi"])
    a.hline(2, 9, 8, p["panel_lo"])
    a.vline(9, 2, 8, p["panel_lo"])
    _cut(a, 12, 12)
    return a


def inset(p: dict, fill_key: str = "inset") -> Art:
    a = Art(8, 8)
    a.rect(0, 0, 8, 8, p["inset_border"])
    a.rect(1, 1, 6, 6, p[fill_key])
    _cut(a, 8, 8)
    return a


def strip(p: dict) -> Art:
    a = Art(12, 14)
    a.rect(0, 0, 12, 14, p["strip"])
    a.hline(0, 0, 12, p["outline"])
    a.hline(0, 1, 12, p["strip_hi"])
    a.hline(0, 12, 12, p["strip_lo"])
    a.hline(0, 13, 12, p["outline"])
    return a


def sheet(p: dict) -> Art:
    a = Art(16, 16)
    a.rect(0, 0, 16, 16, p["outline"])
    a.rect(1, 1, 14, 14, p["strip"])
    a.hline(1, 1, 14, p["strip_hi"])
    a.rect(4, 4, 8, 8, p["outline"])
    a.rect(5, 5, 6, 6, p["panel"])
    a.hline(5, 5, 6, p["panel_hi"])
    _cut(a, 16, 16)
    return a


def toast(p: dict) -> Art:
    a = Art(12, 12)
    a.rect(0, 0, 12, 12, p["outline"])
    a.rect(1, 1, 10, 10, p["gold_border"])
    a.rect(2, 2, 8, 8, p["toast"])
    _cut(a, 12, 12)
    return a


def button(p: dict, face_key: str, state: str) -> Art:
    """12×14 캔버스. normal은 아래 2px 그림자, pressed는 1px 내려가고 그림자 없음."""
    a = Art(12, 14)
    face = p["disabled"] if state == "disabled" else p[face_key]
    top = 2 if state == "pressed" else 0
    body_h = 14 - top
    a.rect(0, top, 12, body_h, p["outline"])
    a.rect(1, top + 1, 10, body_h - 2, shade(face, 0.7))
    a.rect(1, top + 1, 10, body_h - 2 - (0 if state == "pressed" else 2), face)
    a.hline(2, top + 1, 8, shade(face, 1.2))
    _cut(a, 12, 14) if state != "pressed" else None
    if state == "pressed":
        for x, y in ((0, top), (11, top), (0, 13), (11, 13)):
            a.px(x, y, (0, 0, 0, 0))
    return a


def focus_ring(p: dict) -> Art:
    a = Art(12, 14)
    for i in range(12):
        if i % 2 == 0:
            a.px(i, 0, p["focus"])
            a.px(i, 13, p["focus"])
    for j in range(14):
        if j % 2 == 0:
            a.px(0, j, p["focus"])
            a.px(11, j, p["focus"])
    return a


def tab(p: dict, selected: bool) -> Art:
    a = Art(12, 14)
    if selected:
        a.rect(0, 0, 12, 14, p["outline"])
        a.rect(1, 1, 10, 12, p["panel"])
        a.hline(1, 1, 10, p["gold_border"])
        a.hline(1, 2, 10, p["gold_border"])
        _cut(a, 12, 14)
    return a


def chip(p: dict) -> Art:
    a = Art(8, 8)
    a.rect(0, 0, 8, 8, p["inset_border"])
    a.rect(1, 1, 6, 6, p["chip"])
    _cut(a, 8, 8)
    return a


def gauge_bg(p: dict) -> Art:
    a = Art(6, 6)
    a.rect(0, 0, 6, 6, p["outline"])
    a.rect(1, 1, 4, 4, p["gauge_bg"])
    a.hline(1, 1, 4, shade(p["gauge_bg"], 0.7))
    return a


def gauge_fill(color, p: dict) -> Art:
    """4×6 반복 조각. Godot ProgressBar는 채움을 틀 전체 높이로 그리므로 위·아래 외곽선을 포함한다.
    3px 채움 + 1px 어두운 칸막이, 채움 맨 윗줄은 밝은 면."""
    a = Art(4, 6)
    a.hline(0, 0, 4, p["outline"])
    a.hline(0, 5, 4, p["outline"])
    a.rect(0, 1, 3, 4, color)
    a.hline(0, 1, 3, shade(color, 1.25))
    a.vline(3, 1, 4, shade(color, 0.7))
    return a


def toggle(p: dict, on: bool, disabled: bool = False) -> Art:
    a = Art(22, 12)
    track = p["disabled"] if disabled else (p["primary"] if on else p["panel_lo"])
    a.rect(0, 0, 22, 12, p["outline"])
    a.rect(1, 1, 20, 10, track)
    knob_x = 11 if on else 1
    a.rect(knob_x, 1, 10, 10, p["outline"])
    a.rect(knob_x + 1, 2, 8, 8, p["secondary"] if not disabled else p["disabled"])
    a.hline(knob_x + 2, 2, 6, p["panel_hi"])
    _cut(a, 22, 12)
    return a


def grabber(p: dict) -> Art:
    a = Art(4, 8)
    a.rect(0, 0, 4, 8, p["outline"])
    a.rect(1, 1, 2, 6, p["border"])
    return a


def scroll_bg(p: dict) -> Art:
    a = Art(4, 8)
    a.rect(1, 0, 2, 8, p["panel_lo"])
    return a


# 이름 → (그리기, 9분할 여백(아트 px, l t r b), 내용 여백(최종 px, l t r b), 축 반복 여부)
def skin_defs(p: dict) -> dict:
    defs = {
        "window": (window(p), (3, 3, 3, 3), (12, 10, 12, 10), False),
        "window_gold": (window(p, "gold_border"), (3, 3, 3, 3), (12, 10, 12, 10), False),
        "window_accent": (window(p, "accent_border"), (3, 3, 3, 3), (12, 10, 12, 10), False),
        "window_selected": (window(p, "gold_border", "selected"), (3, 3, 3, 3), (12, 10, 12, 10), False),
        "inset": (inset(p), (2, 2, 2, 2), (10, 8, 10, 8), False),
        "strip": (strip(p), (3, 3, 3, 3), (12, 6, 12, 6), False),
        "sheet": (sheet(p), (5, 5, 5, 5), (16, 14, 16, 14), False),
        "toast": (toast(p), (3, 3, 3, 3), (14, 10, 14, 10), False),
        "chip": (chip(p), (2, 2, 2, 2), (8, 2, 8, 2), False),
        "gauge_bg": (gauge_bg(p), (2, 2, 2, 2), (0, 0, 0, 0), False),
        "focus": (focus_ring(p), (3, 3, 3, 3), (0, 0, 0, 0), False),
        "tab_normal": (tab(p, False), (3, 3, 3, 3), (4, 6, 4, 6), False),
        "tab_selected": (tab(p, True), (3, 3, 3, 3), (4, 6, 4, 6), False),
        "scroll_grabber": (grabber(p), (1, 2, 1, 2), (0, 0, 0, 0), False),
        "scroll_bg": (scroll_bg(p), (1, 2, 1, 2), (0, 0, 0, 0), False),
    }
    for kind in ("primary", "gold", "secondary", "danger"):
        for state in ("normal", "pressed", "disabled"):
            content = (12, 8, 12, 10) if state != "pressed" else (12, 10, 12, 8)
            defs[f"button_{kind}_{state}"] = (button(p, kind, state), (3, 3, 3, 4), content, False)
    for key, color in GAUGE_COLORS.items():
        defs[f"gauge_fill_{key}"] = (gauge_fill(color, p), (0, 0, 0, 0), (0, 0, 0, 0), True)
    return defs


ICON_EXTRAS = {
    "toggle_on": lambda p: toggle(p, True),
    "toggle_off": lambda p: toggle(p, False),
    "toggle_disabled": lambda p: toggle(p, False, True),
}


def write_all(out: pathlib.Path) -> list[pathlib.Path]:
    written = []
    (out / "ui").mkdir(parents=True, exist_ok=True)
    (out / "icons").mkdir(parents=True, exist_ok=True)
    (out / "scenes").mkdir(parents=True, exist_ok=True)
    (out / "sprites").mkdir(parents=True, exist_ok=True)
    manifest = {"scale": SCALE, "skins": {}}
    for suffix, palette in PALETTES.items():
        for name, (art, margin, content, tile) in skin_defs(palette).items():
            path = out / "ui" / f"{name}{suffix}.png"
            art.upscale(SCALE).save(path)
            written.append(path)
            if suffix == "":
                manifest["skins"][name] = {
                    "file": f"{name}.png",
                    "size": [art.w * SCALE, art.h * SCALE],
                    "margin": [m * SCALE for m in margin],
                    "content": list(content),
                    "minSize": [max(44, art.w * SCALE) if name.startswith("button") else art.w * SCALE, 44 if name.startswith("button") else art.h * SCALE],
                    "tile": tile,
                }
        for name, maker in ICON_EXTRAS.items():
            path = out / "ui" / f"{name}{suffix}.png"
            maker(palette).upscale(SCALE).save(path)
            written.append(path)
    manifest["highContrastSuffix"] = "_hc"
    manifest_path = out / "ui" / "skins.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    written.append(manifest_path)

    for name in icon_maps.all_icon_names():
        path = out / "icons" / f"{name}.png"
        icon_maps.any_icon(name).img.save(path)
        written.append(path)
    for name, maker in scenes.ENVIRONMENTS.items():
        path = out / "scenes" / f"{name}.png"
        maker(*SCENE_SIZE).img.convert("RGB").save(path)
        written.append(path)
    path = out / "scenes" / "offline_night.png"
    scenes.offline_night(168, 48).img.convert("RGB").save(path)
    written.append(path)

    bubble = Art(18, 20)
    ui_bubble(bubble, 0, 0, 18, 16)
    path = out / "icons" / "bubble.png"
    bubble.img.save(path)
    written.append(path)

    # Godot 합성기가 같은 결과를 내는지 비교할 기준 합성 이미지
    (out / "sprites" / "reference").mkdir(parents=True, exist_ok=True)
    for name, (preset, equipment, expression) in REFERENCE_COMPOSITES.items():
        path = out / "sprites" / "reference" / f"{name}.png"
        trainee.compose(preset, equipment, expression).img.save(path)
        written.append(path)

    sprite_path = out / "sprites" / "trainee.json"
    sprite_path.write_text(json.dumps(trainee_sprite(), ensure_ascii=False, indent=1) + "\n")
    written.append(sprite_path)
    return written


REFERENCE_COMPOSITES = {
    "balanced_plain_smile": ("balanced", {}, "smile"),
    "scholar_formal_robe_wand": ("scholar", {"outfit": "OUTFIT_FORMAL", "armor": "ARM_ROBE", "weapon": "WPN_WAND", "accessory": "ACC_RIBBON"}, "focus"),
    "martial_active_plate_sword": ("martial", {"outfit": "OUTFIT_ACTIVE", "armor": "ARM_PLATE", "weapon": "WPN_SWORD", "accessory": "ACC_JEWEL"}, "smile"),
}

KEY_POOL = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&*+=?@"


def _hex(color) -> str:
    return "#%02x%02x%02x" % color[:3]


def trainee_sprite() -> dict:
    all_layers = trainee.layers("balanced")
    colors: dict[str, str] = {}
    for art in all_layers.values():
        for y in range(art.h):
            for x in range(art.w):
                pixel = art.img.getpixel((x, y))
                if pixel[3] > 0:
                    colors.setdefault(_hex(pixel), "")
    ordered = sorted(colors)
    if len(ordered) > len(KEY_POOL):
        raise SystemExit("페이퍼돌 색이 키 개수보다 많다")
    key_of = {color: KEY_POOL[i] for i, color in enumerate(ordered)}
    layers = {}
    for name, art in all_layers.items():
        rows = []
        for y in range(art.h):
            row = ""
            for x in range(art.w):
                pixel = art.img.getpixel((x, y))
                row += key_of[_hex(pixel)] if pixel[3] > 0 else "."
            rows.append(row)
        layers[name] = rows
    recolor = {}
    for preset in trainee.OUTFIT_COLORS:
        mapping = {}
        for src, dst in trainee.recolor_map(preset).items():
            if _hex(src) in key_of:
                mapping[key_of[_hex(src)]] = _hex(dst)
        recolor[preset] = mapping
    return {
        "size": [trainee.W, trainee.H],
        "keys": {key_of[c]: c for c in ordered},
        "recolor": recolor,
        "order": list(trainee.ORDER),
        "defaults": {"outfit": "OUTFIT_PLAIN", "expression": "smile"},
        "layers": layers,
    }


def contract_markdown(manifest_path: pathlib.Path) -> str:
    manifest = json.loads(manifest_path.read_text())
    lines = [
        "# UI 스킨 계약 (방향 A. 아카데미 방)",
        "",
        "`scripts/pixel_art/generate.py`가 `godot/assets/pixel/ui/skins.json`과 함께 만든다. 직접 고치지 말고 생성기를 고친다.",
        "모든 값은 최종 파일 px(아트 1px = 2px)이다. 고대비 스킨은 같은 이름에 `_hc`를 붙인 파일이고 크기와 분할이 같다.",
        "",
        "| 구성요소·상태 | 파일 | 크기 | 9분할 좌/상/우/하 | 내용 여백 좌/상/우/하 | 최소 표시 크기 | 가로 반복 |",
        "|---|---|---|---|---|---|---|",
    ]
    for name, entry in manifest["skins"].items():
        lines.append("| `%s` | `%s` | %d×%d | %s | %s | %d×%d | %s |" % (
            name, entry["file"], entry["size"][0], entry["size"][1],
            "/".join(str(v) for v in entry["margin"]), "/".join(str(v) for v in entry["content"]),
            entry["minSize"][0], entry["minSize"][1], "예" if entry["tile"] else "",
        ))
    lines += [
        "",
        "버튼 상태는 같은 12×14 아트 캔버스를 쓴다. normal은 아래 2px 그림자, pressed는 1 아트픽셀 내려가고 그림자가 없다. focus는 바깥 점선 테두리만 있는 덧그림이다.",
        "토글 아이콘(`toggle_on`, `toggle_off`, `toggle_disabled`)은 44×24이고 CheckButton 아이콘으로 쓴다.",
        "",
    ]
    return "\n".join(lines)


def _same(a: pathlib.Path, b: pathlib.Path) -> bool:
    if a.suffix == ".png":
        ia, ib = Image.open(a).convert("RGBA"), Image.open(b).convert("RGBA")
        return ia.size == ib.size and ImageChops.difference(ia, ib).getbbox() is None
    return a.read_bytes() == b.read_bytes()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if not args.check:
        written = write_all(OUT)
        CONTRACT_DOC.write_text(contract_markdown(OUT / "ui" / "skins.json"))
        print(f"generated {len(written)} files in {OUT.relative_to(ROOT)} and {CONTRACT_DOC.relative_to(ROOT)}")
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        written = write_all(pathlib.Path(tmp))
        problems = []
        for path in written:
            committed = OUT / path.relative_to(tmp)
            if not committed.exists():
                problems.append(f"missing {committed.relative_to(ROOT)}")
            elif not _same(path, committed):
                problems.append(f"differs {committed.relative_to(ROOT)}")
        if not CONTRACT_DOC.exists() or CONTRACT_DOC.read_text() != contract_markdown(pathlib.Path(tmp) / "ui" / "skins.json"):
            problems.append(f"differs {CONTRACT_DOC.relative_to(ROOT)}")
        expected = {p.relative_to(tmp) for p in written}
        for existing in OUT.rglob("*"):
            if existing.is_file() and existing.suffix in (".png", ".json") and existing.relative_to(OUT) not in expected:
                problems.append(f"stale {existing.relative_to(ROOT)}")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 1
    print(f"pixel assets match generator ({len(written)} files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
