"""Render the Windows startup BMP with the same identity as the Ranwar menu."""

import argparse
from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
SIZE = (720, 405)
SCALE = 2
IVORY = "#F1EDE2"
AMBER = "#FFC247"


def copyright_text():
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    copyright_line = re.search(r"^Copyright \(c\) (\d{4} [^.\r\n]+)\.", license_text, re.MULTILINE)
    if copyright_line is None:
        raise ValueError("The project license is missing its copyright year and owner.")
    return f"© {copyright_line.group(1)}"


def render_splash(font_dir):
    width, height = (size * SCALE for size in SIZE)
    with Image.open(ROOT / "unreal/ContentSource/UI/title-backdrop.jpg") as backdrop:
        canvas = backdrop.convert("RGBA").resize((width, height), Image.Resampling.LANCZOS)

    # Keep the rickshaw and illuminated buildings clear on the right.
    fade = Image.new("L", (width, 1))
    fade.putdata([round(135 * max(0.0, min(1.0, (410 - x / SCALE) / 210))) for x in range(width)])
    shade = Image.new("RGBA", canvas.size, "#07111E")
    shade.putalpha(fade.resize(canvas.size, Image.Resampling.NEAREST))
    canvas.alpha_composite(shade)

    with Image.open(ROOT / "prototype/startup/art/amg-mark.png") as source:
        mark = source.convert("RGBA").resize((78 * SCALE, 78 * SCALE), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, (35 * SCALE, 41 * SCALE))

    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(str(font_dir / "Roboto-BoldCondensed.ttf"), 50 * SCALE)
    subtitle_font = ImageFont.truetype(str(font_dir / "Roboto-Bold.ttf"), 21 * SCALE)
    footer_font = ImageFont.truetype(str(font_dir / "Roboto-Regular.ttf"), 15 * SCALE)
    draw.text((35 * SCALE, 130 * SCALE), "Aamchi", font=title_font, fill=IVORY, anchor="lt")
    draw.text((35 * SCALE, 182 * SCALE), "Mumbai Game", font=title_font, fill=IVORY, anchor="lt")
    draw.text((37 * SCALE, 244 * SCALE), "Our Mumbai", font=subtitle_font, fill=AMBER, anchor="lt")
    draw.text((36 * SCALE, 329 * SCALE), "Loading…", font=footer_font, fill=IVORY, anchor="lt")
    draw.text((36 * SCALE, 370 * SCALE), copyright_text(), font=footer_font, fill="#CFD7E3", anchor="lt")
    return canvas.convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font_dir", type=Path, help="UE 5.8 Engine/Content/Slate/Fonts directory")
    parser.add_argument("--preview", type=Path, help="Optional PNG preview to save")
    args = parser.parse_args()
    splash = render_splash(args.font_dir)
    splash.save(ROOT / "unreal/Content/Splash/Splash.bmp", format="BMP")
    if args.preview is not None:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        splash.save(args.preview, format="PNG")
