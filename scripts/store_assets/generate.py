"""Google Play 등록·Android 런처 그림을 게임의 도트 원본으로 만든다.

    python3 scripts/store_assets/generate.py            # 만들기
    python3 scripts/store_assets/generate.py --check    # 다시 만든 결과가 커밋된 파일과 같은지 확인

이미지 생성 API를 쓰지 않고 scripts/pixel_art의 장면·수련생 도트와 번들 OFL 픽셀 폰트만 쓴다.
모든 그림은 아트 1px을 정수배로 nearest 확대한다.
"""
from __future__ import annotations

import argparse
import pathlib
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "pixel_art"))

import scenes  # noqa: E402
import trainee  # noqa: E402
from pixellib import Art, font, rgb, shade  # noqa: E402

PLAY_DIR = ROOT / "play-store" / "assets"
ANDROID_DIR = ROOT / "godot" / "assets" / "android"

GOLD = rgb("e9b949")
GOLD_SHADE = rgb("a87a2a")
INK = rgb("2b1a10")
CREAM = rgb("fff4dc")
WOOD_DARK = rgb("3a2414")


def _figure() -> Art:
    return trainee.compose("balanced", {"outfit": "OUTFIT_FORMAL", "accessory": "ACC_RIBBON"}, "smile")


def _room(w: int, h: int) -> Art:
    return scenes.study_room(w, h, "warm")


def _vignette(a: Art, depth: int, strength: float) -> None:
    """가장자리를 단계적으로 어둡게 해 인물을 띄운다(도트 단위)."""
    for step in range(depth):
        factor = 1.0 - strength * (depth - step) / depth
        for x in range(step, a.w - step):
            for y in (step, a.h - 1 - step):
                a.px(x, y, shade(a.get(x, y), factor))
        for y in range(step + 1, a.h - 1 - step):
            for x in (step, a.w - 1 - step):
                a.px(x, y, shade(a.get(x, y), factor))


NAVY = rgb("2a3166")
NAVY_DARK = rgb("1c2148")
STAR = rgb("ffe9a0")


def _badge(size: int) -> Art:
    """아이콘 바탕: 진한 남색에 체커 디더와 작은 별. 작게 줄어도 얼굴이 먼저 보이게 단순하게 둔다."""
    a = Art(size, size, NAVY)
    a.dither(0, size // 2, size, size - size // 2, NAVY_DARK + (255,) if len(NAVY_DARK) == 3 else NAVY_DARK)
    for x, y in ((4, 5), (size - 6, 3), (size - 4, 10)):
        a.px(x, y, STAR)
    return a


def _icon_art() -> Art:
    """아트 32px 아이콘: 얼굴(28px)을 바탕 아래쪽에 붙여 크게 보인다."""
    a = _badge(32)
    a.blit(trainee.portrait("balanced", 28), 2, 4)
    return a


def play_icon() -> Image.Image:
    """512×512 전면 정사각형(아트 32px ×16). Play가 모서리를 다듬으므로 직접 둥글리지 않는다."""
    return _icon_art().upscale(16)


def launcher_main() -> Image.Image:
    """192×192 기본 런처 아이콘(아트 32px ×6)."""
    return _icon_art().upscale(6)


def adaptive_background() -> Image.Image:
    """432×432 적응형 배경(아트 36px ×12)."""
    return _badge(36).upscale(12)


def adaptive_foreground() -> Image.Image:
    """432×432 적응형 앞면(아트 36px ×12). 얼굴은 가운데 보이는 영역(72dp = 아트 24px) 안에 둔다."""
    a = Art(36, 36)
    a.blit(trainee.portrait("balanced", 24), 6, 6)
    return a.upscale(12)


def adaptive_monochrome() -> Image.Image:
    """432×432 단색(테마 아이콘). 앞면의 실루엣만 흰색으로."""
    fg = adaptive_foreground()
    alpha = fg.getchannel("A").point(lambda v: 255 if v > 0 else 0)
    mono = Image.new("RGBA", fg.size, (255, 255, 255, 0))
    mono.putalpha(alpha)
    return mono


def feature_graphic() -> Image.Image:
    """1024×500 대표 이미지(아트 256×125 ×4). 오른쪽에 수련생, 왼쪽에 제목."""
    a = _room(256, 125)
    _vignette(a, 10, 0.4)
    figure = _figure()
    big = Art(figure.w * 2, figure.h * 2)
    big.blit(figure.img.resize((figure.w * 2, figure.h * 2), Image.NEAREST), 0, 0)
    a.blit(big, 256 - big.w - 20, 125 - big.h)
    # 제목 판: 단색 창 바탕 위에만 글자를 놓는다.
    plate = (14, 28, 132, 62)
    a.rect(plate[0] - 2, plate[1] - 2, plate[2] + 4, plate[3] + 4, GOLD_SHADE)
    a.rect(plate[0] - 1, plate[1] - 1, plate[2] + 2, plate[3] + 2, GOLD)
    a.rect(plate[0], plate[1], plate[2], plate[3], WOOD_DARK)
    img = a.upscale(4).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    title = font("title", 72)
    sub = font("body", 32)
    left = plate[0] * 4 + 40
    d.text((left + 4, plate[1] * 4 + 44), "왕립 아카데미", font=title, fill=INK)
    d.text((left, plate[1] * 4 + 40), "왕립 아카데미", font=title, fill=GOLD)
    d.text((left, plate[1] * 4 + 150), "수련생 육성 시뮬레이션", font=sub, fill=CREAM)
    return img


OUTPUTS = {
    PLAY_DIR / "icon-512.png": play_icon,
    PLAY_DIR / "feature-graphic-1024x500.png": feature_graphic,
    ANDROID_DIR / "launcher-192.png": launcher_main,
    ANDROID_DIR / "adaptive-foreground-432.png": adaptive_foreground,
    ANDROID_DIR / "adaptive-background-432.png": adaptive_background,
    ANDROID_DIR / "adaptive-monochrome-432.png": adaptive_monochrome,
}


def _write(target_root: pathlib.Path) -> list[pathlib.Path]:
    written = []
    for path, maker in OUTPUTS.items():
        out = target_root / path.relative_to(ROOT)
        out.parent.mkdir(parents=True, exist_ok=True)
        image = maker()
        if path.name in ("icon-512.png", "feature-graphic-1024x500.png", "launcher-192.png", "adaptive-background-432.png"):
            image = image.convert("RGB")  # 불투명 그림은 알파 없이 저장한다(Play 대표 이미지 규칙).
        image.save(out, optimize=True)
        written.append(out)
    return written


def _same(a: pathlib.Path, b: pathlib.Path) -> bool:
    if not a.exists() or not b.exists():
        return False
    with Image.open(a) as left, Image.open(b) as right:
        if left.size != right.size or left.mode != right.mode:
            return False
        return ImageChops.difference(left.convert("RGBA"), right.convert("RGBA")).getbbox() is None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if not args.check:
        for path in _write(ROOT):
            print(path.relative_to(ROOT))
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        fresh = _write(pathlib.Path(tmp))
        bad = [p.relative_to(tmp) for p in fresh if not _same(p, ROOT / p.relative_to(tmp))]
    if bad:
        print("store assets differ from generator:", ", ".join(str(p) for p in bad))
        return 1
    print(f"store assets match generator ({len(OUTPUTS)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
