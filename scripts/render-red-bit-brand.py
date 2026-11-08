#!/usr/bin/env python3
"""Rendert den eigenen Signalband-Marker ohne Laufzeitabhängigkeiten der App.

Entwicklungswerkzeuge: resvg-py 0.5.0 (MIT), Pillow 13.0.0 (HPND).
Installation und Aufruf stehen in artwork/red-bit/README.md.
"""
from io import BytesIO
from pathlib import Path
import json
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "build/brand-tools"))
import resvg_py
from PIL import Image, ImageDraw, ImageFont


def main():
    directory = ROOT / "artwork/red-bit"
    mark = (directory / "signal-mark.svg").read_text(encoding="utf-8")
    path = ET.fromstring(mark).find("{http://www.w3.org/2000/svg}path").attrib["d"]
    glyph = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><path transform="translate(12 0) scale(10)" d="{path}" fill="#FFF9F0"/></svg>\n'
    icon = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <defs><linearGradient id="red" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FF5A42"/><stop offset="0.52" stop-color="#D62236"/><stop offset="1" stop-color="#7C1028"/></linearGradient></defs>
  <path fill="url(#red)" d="M0 0H1024V1024H0Z"/>
  <path transform="translate(12 0) scale(10)" d="{path}" fill="#FFF9F0"/>
</svg>\n'''
    (directory / "signal-glyph.svg").write_text(glyph, encoding="utf-8")
    (directory / "signal-icon.svg").write_text(icon, encoding="utf-8")
    png = resvg_py.svg_to_bytes(svg_string=icon, width=1024, height=1024)
    image = Image.open(BytesIO(png)).convert("RGB")
    image.save(directory / "signal-icon-1024.png")
    image.save(ROOT / "AppleApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    (ROOT / "AppleApp/Assets.xcassets/bch-logo.imageset/bch-logo.svg").write_text(mark, encoding="utf-8")
    (ROOT / "AppleApp/AppIcon.icon/Assets/rbit.svg").write_text(glyph, encoding="utf-8")
    composer_path = ROOT / "AppleApp/AppIcon.icon/icon.json"
    composer = json.loads(composer_path.read_text(encoding="utf-8"))
    composer["fill"]["linear-gradient"] = ["srgb:1.00000,0.35294,0.25882,1.00000", "srgb:0.48627,0.06275,0.15686,1.00000"]
    composer_path.write_text(json.dumps(composer, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Unabhängige Sichtprüfung: große Form, helle/dunkle Toolbar und kleine Größen.
    board = Image.new("RGB", (1440, 900), "#F4F0E9")
    draw = ImageDraw.Draw(board)
    font_path = Path("C:/Windows/Fonts/segoeui.ttf")
    font = ImageFont.truetype(str(font_path), 66) if font_path.exists() else ImageFont.load_default(size=66)
    small = ImageFont.truetype(str(font_path), 24) if font_path.exists() else ImageFont.load_default(size=24)
    title = ImageFont.truetype(str(font_path), 30) if font_path.exists() else ImageFont.load_default(size=30)
    draw.text((76, 54), "RED Bit", font=font, fill="#21191A")
    draw.text((80, 145), "Signalband · Klang als Zeichen", font=small, fill="#655354")
    tile = image.resize((490, 490), Image.Resampling.LANCZOS)
    mask = Image.new("L", (490, 490))
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 489, 489), radius=105, fill=255)
    board.paste(tile, (78, 241), mask)
    draw.text((690, 240), "Ein R. Ein unterbrochenes Signal.", font=title, fill="#21191A")
    draw.text((690, 289), "Die Öffnung bleibt auch als 24-pt-Marker lesbar.", font=small, fill="#655354")
    for y, background, foreground in [(365, "#FFFFFF", "#201A1B"), (515, "#21191A", "#FFF9F0")]:
        draw.rounded_rectangle((686, y, 1344, y + 118), radius=26, fill=background)
        for x, size in [(718, 28), (806, 44), (924, 64)]:
            svg = mark.replace('#000000', foreground)
            raster = Image.open(BytesIO(resvg_py.svg_to_bytes(svg_string=svg, width=size * 3, height=size * 3))).convert("RGBA")
            raster.thumbnail((size, size), Image.Resampling.LANCZOS)
            board.paste(raster, (x, y + (118 - size) // 2), raster)
        draw.text((1060, y + 43), "RED Bit", font=small, fill=foreground)
    draw.text((78, 805), "Eigener Vektorentwurf · App-Icon / Toolbar / Music Island", font=small, fill="#655354")
    board.save(directory / "signal-brand-preview.png")
    print("Signalband: Vektoren, RGB-App-Icon und Markenübersicht erzeugt.")


if __name__ == "__main__":
    main()
