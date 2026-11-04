"""Princess Tycoon 픽셀 아트 공용 도구.

모든 아트는 1배 캔버스(아트 1px)에 그린 뒤 2배 nearest로 키운다. 화면 논리 좌표 390×844에서
아트 1px = 논리 2px이다. 글자는 키운 뒤 논리 좌표에 안티앨리어싱 없이 그린다.
이미지 생성 API나 외부 이미지를 쓰지 않고 코드와 픽셀맵만으로 만든다.
"""
from __future__ import annotations

import pathlib
import random
from functools import lru_cache

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "godot" / "assets" / "fonts"
SCALE = 2

FONT_FILES = {
    "body": "NeoDunggeunmo-Regular.ttf",
    "title": "Galmuri11-Bold.ttf",
}


def rgb(value: str) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


def shade(color: tuple, factor: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * factor))),
        max(0, min(255, int(color[1] * factor))),
        max(0, min(255, int(color[2] * factor))),
        color[3] if len(color) > 3 else 255,
    )


@lru_cache(maxsize=None)
def font(role: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / FONT_FILES[role]), size)


class Art:
    """아트 1px 단위 RGBA 캔버스."""

    def __init__(self, width: int, height: int, fill=None):
        self.w = width
        self.h = height
        self.img = Image.new("RGBA", (width, height), fill if fill else (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def px(self, x: int, y: int, color) -> None:
        if 0 <= x < self.w and 0 <= y < self.h and color is not None:
            self.img.putpixel((x, y), color)

    def get(self, x: int, y: int):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.img.getpixel((x, y))
        return (0, 0, 0, 0)

    def rect(self, x: int, y: int, w: int, h: int, color) -> None:
        if w <= 0 or h <= 0 or color is None:
            return
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=color)

    def hline(self, x: int, y: int, w: int, color) -> None:
        self.rect(x, y, w, 1, color)

    def vline(self, x: int, y: int, h: int, color) -> None:
        self.rect(x, y, 1, h, color)

    def box(self, x: int, y: int, w: int, h: int, color) -> None:
        self.hline(x, y, w, color)
        self.hline(x, y + h - 1, w, color)
        self.vline(x, y, h, color)
        self.vline(x + w - 1, y, h, color)

    def ellipse(self, x0: int, y0: int, x1: int, y1: int, color) -> None:
        self.d.ellipse([x0, y0, x1, y1], fill=color)

    def poly(self, points, color) -> None:
        self.d.polygon(points, fill=color)

    def blit(self, other: "Art | Image.Image", x: int, y: int) -> None:
        source = other.img if isinstance(other, Art) else other
        self.img.alpha_composite(source, (x, y))

    def dither(self, x: int, y: int, w: int, h: int, color, phase: int = 0) -> None:
        """체커 패턴으로 색을 얹는다. 반투명 색은 아래 픽셀과 섞어 불투명하게 칠한다."""
        alpha = (color[3] if len(color) > 3 else 255) / 255.0
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if (xx + yy + phase) % 2 != 0 or not (0 <= xx < self.w and 0 <= yy < self.h):
                    continue
                under = self.img.getpixel((xx, yy))
                mixed = tuple(int(under[i] * (1 - alpha) + color[i] * alpha) for i in range(3)) + (255,)
                self.px(xx, yy, mixed)

    def upscale(self, factor: int = SCALE) -> Image.Image:
        return self.img.resize((self.w * factor, self.h * factor), Image.NEAREST)


def from_rows(rows: list[str], palette: dict[str, tuple]) -> Art:
    """팔레트 키 문자열 행을 1배 아트로 바꾼다. '.'는 투명."""
    art = Art(max(len(r) for r in rows), len(rows))
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key != "." and key != " ":
                art.px(x, y, palette[key])
    return art


def selective_outline(art: Art, outline_for) -> None:
    """불투명 픽셀 중 투명과 맞닿은 테두리 픽셀을 자기 색의 어두운 단계로 바꾼다."""
    src = art.img.copy()
    for y in range(art.h):
        for x in range(art.w):
            color = src.getpixel((x, y))
            if color[3] == 0:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < art.w and 0 <= ny < art.h) or src.getpixel((nx, ny))[3] == 0:
                    edge = True
                    break
            if edge:
                art.px(x, y, outline_for(color))


class Screen:
    """논리 390×844 화면. 1배 아트를 2배로 키운 뒤 글자를 논리 좌표에 그린다."""

    def __init__(self, art: Art):
        self.img = art.upscale(SCALE).convert("RGBA")
        self.d = ImageDraw.Draw(self.img)
        self.d.fontmode = "1"

    def text(self, x: int, y: int, value: str, role: str = "body", size: int = 16, color=(255, 255, 255, 255),
             shadow=None, align: str = "left", width: int = 0) -> int:
        f = font(role, size)
        tw = int(self.d.textlength(value, font=f))
        if align == "center":
            x = x + (width - tw) // 2
        elif align == "right":
            x = x + width - tw
        x -= x % 2
        if shadow is not None:
            self.d.text((x + 2, y + 2), value, font=f, fill=shadow)
        self.d.text((x, y), value, font=f, fill=color)
        return tw

    def measure(self, value: str, role: str = "body", size: int = 16) -> int:
        return int(self.d.textlength(value, font=font(role, size)))

    def wrap(self, value: str, max_width: int, role: str = "body", size: int = 16) -> list[str]:
        lines, current = [], ""
        for word in value.split(" "):
            candidate = word if not current else current + " " + word
            if self.measure(candidate, role, size) <= max_width:
                current = candidate
            else:
                if current:
                    lines.append(current)
                current = word
        if current:
            lines.append(current)
        return lines

    def save(self, path) -> None:
        self.img.convert("RGB").save(path)


def seeded(seed: int) -> random.Random:
    return random.Random(seed)
