"""기존 warm 팔레트와 코드 도트로 PixelLab의 정지·루프 참조를 만든다."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/pixel_art"))
from pixellib import Art, rgb  # noqa: E402
from scenes import THEMES  # noqa: E402
from trainee import BASE_PALETTE as P  # noqa: E402

OUT = ROOT / "godot/assets/pixel_animations/references"
T = {key: rgb(value) for key, value in THEMES["warm"].items() if isinstance(value, str)}


def book(ledger=False):
    a = Art(64, 64)
    a.poly([(13, 29), (29, 26), (32, 29), (35, 26), (51, 29), (51, 45), (35, 44), (32, 47), (29, 44), (13, 45)], T["line"])
    a.poly([(14, 29), (29, 27), (32, 30), (35, 27), (50, 29), (50, 43), (35, 42), (32, 45), (29, 42), (14, 43)], P["ribbon_shade"] if ledger else P["cloth"])
    a.poly([(15, 28), (28, 25), (32, 28), (36, 25), (49, 28), (49, 40), (36, 38), (32, 42), (28, 38), (15, 40)], P["blouse_shade"])
    a.poly([(16, 28), (28, 26), (31, 29), (31, 40), (28, 37), (16, 39)], P["blouse"])
    a.poly([(33, 29), (36, 26), (48, 28), (48, 39), (36, 37), (33, 40)], P["white"])
    a.vline(32, 29, 13, T["wood_light"])
    for y in (30, 33, 36):
        a.hline(18, y, 9, P["blouse_shade"])
        a.hline(37, y, 8, P["blouse_shade"])
    if ledger:
        a.poly([(41, 39), (44, 40), (53, 24), (50, 23)], T["line"])
        a.poly([(43, 38), (44, 37), (51, 24), (50, 24)], P["trim"])
        a.rect(16, 43, 5, 3, P["trim"])
    return a


def reference(name):
    if name in ("book", "ledger"):
        return book(name == "ledger")
    a = Art(64, 64)
    if name == "magic":
        a.ellipse(22, 17, 43, 38, P["robe_shade"])
        a.ellipse(23, 18, 42, 37, P["gem_shade"])
        a.ellipse(25, 19, 39, 33, P["gem"])
        a.rect(27, 21, 4, 3, P["white"])
        a.poly([(22, 40), (26, 37), (39, 37), (43, 40), (40, 44), (25, 44)], T["line"])
        a.rect(26, 39, 13, 4, P["trim_shade"])
        a.hline(26, 39, 13, P["trim"])
        for x, y in [(18, 20), (46, 27), (21, 34)]:
            a.rect(x, y - 1, 1, 3, P["star"])
            a.rect(x - 1, y, 3, 1, P["star"])
    elif name == "tea":
        a.ellipse(14, 39, 50, 46, T["line"])
        a.ellipse(16, 39, 48, 44, P["blouse_shade"])
        a.ellipse(40, 29, 50, 39, P["blouse"])
        a.ellipse(42, 31, 47, 36, T["wood_dark"])
        a.poly([(20, 28), (43, 28), (41, 39), (37, 42), (26, 42), (22, 39)], T["line"])
        a.poly([(22, 29), (41, 29), (39, 38), (36, 40), (27, 40), (24, 38)], P["blouse"])
        a.ellipse(22, 26, 41, 31, P["blouse_shade"])
        a.ellipse(24, 27, 39, 30, T["wood_dark"])
        a.poly([(28, 23), (26, 20), (27, 16), (29, 13), (29, 16), (28, 20), (30, 23)], P["blouse"])
        a.poly([(35, 24), (34, 20), (36, 17), (37, 12), (38, 16), (36, 21), (37, 24)], P["blouse_shade"])
    elif name == "compass":
        a.rect(29, 13, 6, 5, P["trim_shade"])
        a.box(29, 13, 6, 5, T["line"])
        a.ellipse(16, 17, 48, 49, T["line"])
        a.ellipse(18, 19, 46, 47, P["trim_shade"])
        a.ellipse(20, 21, 44, 45, P["trim"])
        a.ellipse(22, 23, 42, 43, P["blouse"])
        a.poly([(32, 24), (36, 33), (32, 33), (28, 33)], P["ribbon"])
        a.poly([(32, 42), (36, 33), (28, 33)], P["gem_shade"])
        a.rect(31, 32, 3, 3, T["line"])
        for x, y in [(24, 32), (40, 32), (31, 24), (31, 40)]:
            a.rect(x, y, 2, 2, T["wood_dark"])
    elif name == "flag":
        a.rect(19, 13, 3, 36, T["line"])
        a.vline(20, 14, 34, P["trim"])
        a.ellipse(18, 10, 22, 14, P["trim"])
        a.poly([(22, 14), (48, 16), (44, 25), (48, 32), (22, 30)], T["line"])
        a.poly([(22, 16), (45, 18), (41, 25), (45, 30), (22, 28)], P["cloth"])
        a.hline(23, 17, 18, P["cloth_light"])
        a.poly([(32, 19), (34, 23), (38, 23), (35, 25), (36, 28), (32, 26), (29, 28), (30, 24), (27, 22), (31, 22)], P["trim"])
        a.rect(15, 48, 12, 3, T["line"])
        a.hline(16, 48, 10, P["trim_shade"])
    elif name == "candle":
        a.ellipse(20, 44, 44, 49, T["line"])
        a.ellipse(22, 44, 42, 47, P["trim_shade"])
        a.rect(30, 39, 5, 7, P["trim"])
        a.rect(26, 25, 13, 17, T["line"])
        a.rect(27, 26, 11, 14, P["blouse_shade"])
        a.rect(28, 26, 7, 14, P["blouse"])
        a.rect(34, 27, 2, 5, P["white"])
        a.vline(32, 22, 4, T["line"])
        a.poly([(32, 12), (36, 19), (35, 23), (30, 23), (28, 20)], P["trim_shade"])
        a.poly([(32, 13), (35, 20), (33, 23), (30, 21)], P["trim"])
        a.poly([(32, 18), (33, 22), (31, 22)], P["white"])
    elif name == "leaves":
        for x, y, col in [(19, 17, "3e7a52"), (39, 28, "c48a2e"), (24, 40, "7a8c4a")]:
            a.poly([(x - 4, y), (x - 1, y - 4), (x + 6, y - 4), (x + 5, y + 2), (x + 1, y + 5)], T["line"])
            a.poly([(x - 3, y), (x, y - 3), (x + 5, y - 3), (x + 4, y + 1), (x + 1, y + 4)], rgb(col))
            a.poly([(x - 2, y + 3), (x + 4, y - 2), (x + 1, y + 2)], P["trim_shade"])
    return a


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ("book", "magic", "ledger", "tea", "compass", "flag", "candle", "leaves"):
        reference(name).img.save(OUT / f"{name}.png")
    print("8 references: warm room + trainee palette, 64x64 RGBA")
