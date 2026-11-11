#!/usr/bin/env python3
"""Erzeugt alle App-Logo-Dateien aus dem Wellen-Logo des Nutzers (11.11.2026).

Quelle: artwork/red-bit/wave-source.webp (abgerundetes Quadrat auf Transparenz).
Werkzeuge: Pillow und NumPy, nur lokal zur Entwicklung; die App bekommt keine
neue Abhängigkeit.

Ausgaben:
- Legacy-App-Icon 1024 × 1024 RGB ohne Alpha, randlos (iOS maskiert selbst)
- Icon-Composer-Ebene mit der schattierten Welle (iOS/macOS 26, Liquid Glass)
- Template-Marker für Toolbar, Onboarding und Konto (Deckkraft trägt die Schattierung)
- Vorschau-Board zur Sichtprüfung
"""
from collections import deque
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "artwork/red-bit"
# Gemessenes abgerundetes Quadrat in der Quelle (1254 × 1254): x 174…1070, y 187…1069.
CROP = (174, 180, 1071, 1077)
INNER = (8, 15, 888, 881)
INNER_RADIUS = 232


def diffuse(image, known, iterations):
    """Füllt unbekannte Pixel mit dem Mittel ihrer Nachbarn (glatter Verlauf)."""
    image = image.copy()
    for _ in range(iterations):
        padded = np.pad(image, ((1, 1), (1, 1), (0, 0)), mode="edge")
        average = (padded[:-2, 1:-1] + padded[2:, 1:-1] + padded[1:-1, :-2] + padded[1:-1, 2:]) / 4
        image[~known] = average[~known]
    return image


def components(mask):
    """Zusammenhängende Flächen (4er-Nachbarschaft) mit ihren Größen."""
    labels = np.zeros(mask.shape, np.int32)
    sizes = []
    height, width = mask.shape
    for y0 in range(height):
        for x0 in np.where(mask[y0] & (labels[y0] == 0))[0]:
            if labels[y0, x0]:
                continue
            label = len(sizes) + 1
            queue = deque([(y0, x0)])
            labels[y0, x0] = label
            size = 0
            while queue:
                y, x = queue.popleft()
                size += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < height and 0 <= xx < width and mask[yy, xx] and not labels[yy, xx]:
                        labels[yy, xx] = label
                        queue.append((yy, xx))
            sizes.append(size)
    return labels, sizes


def main():
    source = Image.open(ART / "wave-source.webp").convert("RGBA")
    crop = source.crop(CROP)
    rgb = np.asarray(crop).astype(np.float64)[..., :3]

    # 1. Randloses Icon: Ecken außerhalb des abgerundeten Quadrats glatt auffüllen.
    inner = Image.new("L", crop.size, 0)
    ImageDraw.Draw(inner).rounded_rectangle(INNER, radius=INNER_RADIUS, fill=255)
    known = np.asarray(inner) > 128
    fill = rgb.copy()
    fill[~known] = rgb[known].mean(axis=0)
    coarse = np.asarray(Image.fromarray(fill.astype(np.uint8)).resize((128, 128), Image.LANCZOS)).astype(np.float64)
    coarse_known = np.asarray(inner.resize((128, 128), Image.BOX)) > 250
    coarse = diffuse(coarse, coarse_known, 900)
    upscaled = np.asarray(Image.fromarray(coarse.clip(0, 255).astype(np.uint8)).resize(crop.size, Image.BICUBIC))
    fill[~known] = upscaled.astype(np.float64)[~known]
    fill = diffuse(fill, known, 250)
    feather = np.asarray(inner.filter(ImageFilter.GaussianBlur(3))).astype(np.float64)[..., None] / 255
    icon = Image.fromarray((rgb * feather + fill * (1 - feather)).clip(0, 255).astype(np.uint8), "RGB")
    icon = icon.resize((1024, 1024), Image.LANCZOS)
    icon.save(ART / "wave-icon-1024.png")
    icon.save(ROOT / "AppleApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

    # 2. Welle freistellen: Creme unterscheidet sich vom Bordeaux durch geringe Rötung.
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    redness = (red - (green + blue) / 2) / np.maximum(red, 1)
    soft = np.clip((0.55 - redness) / (0.55 - 0.42), 0, 1) * known
    binary = Image.fromarray(((soft > 0.5) * 255).astype(np.uint8), "L")
    binary = binary.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))
    binary = binary.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5))
    labels, sizes = components(np.asarray(binary) > 128)
    clean = np.isin(labels, [index + 1 for index, size in enumerate(sizes) if size > 3000])
    edge = np.asarray(Image.fromarray((clean * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))) / 255
    alpha = Image.fromarray((np.minimum(soft, edge) * 255).astype(np.uint8), "L").resize((1024, 1024), Image.LANCZOS)
    layer = Image.fromarray(rgb.clip(0, 255).astype(np.uint8), "RGB").resize((1024, 1024), Image.LANCZOS).convert("RGBA")
    layer.putalpha(alpha)
    composer_assets = ROOT / "AppleApp/AppIcon.icon/Assets"
    layer.save(composer_assets / "wave.png")
    layer.save(ART / "wave-glyph.png")
    old_layer = composer_assets / "rbit.svg"
    if old_layer.exists():
        old_layer.unlink()

    composer_path = ROOT / "AppleApp/AppIcon.icon/icon.json"
    composer = json.loads(composer_path.read_text(encoding="utf-8"))
    composer["fill"] = {"linear-gradient": ["srgb:0.49412,0.08235,0.20392,1.00000",
                                            "srgb:0.20000,0.00392,0.03529,1.00000"]}
    group = composer["groups"][0]
    group["layers"] = [{"glass": False, "image-name": "wave.png", "name": "wave"}]
    group["shadow"] = {"kind": "neutral", "opacity": 0.5}
    group["translucency"] = {"enabled": False, "value": 0}
    composer_path.write_text(json.dumps(composer, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # 3. Template-Marker: Deckkraft folgt der Helligkeit, so bleibt die Drehung lesbar.
    pixels = np.asarray(layer).astype(np.float64)
    luminance = 0.299 * pixels[..., 0] + 0.587 * pixels[..., 1] + 0.114 * pixels[..., 2]
    opacity = pixels[..., 3] / 255
    inside = opacity > 0.9
    low, high = np.percentile(luminance[inside], 3), np.percentile(luminance[inside], 97)
    shade = np.clip((luminance - low) / (high - low), 0, 1)
    mark_alpha = opacity * (0.30 + 0.70 * shade)
    ys, xs = np.where(opacity > 0.5)
    box = (int(xs.min()) - 8, int(ys.min()) - 8, int(xs.max()) + 9, int(ys.max()) + 9)
    zeros = np.zeros_like(luminance)
    mark = Image.fromarray(np.dstack([zeros, zeros, zeros, mark_alpha * 255]).astype(np.uint8), "RGBA").crop(box)
    mark = mark.resize((600, round(mark.size[1] * 600 / mark.size[0])), Image.LANCZOS)
    imageset = ROOT / "AppleApp/Assets.xcassets/bch-logo.imageset"
    mark.save(imageset / "bch-logo.png")
    mark.save(ART / "wave-mark.png")
    old_mark = imageset / "bch-logo.svg"
    if old_mark.exists():
        old_mark.unlink()
    (imageset / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "bch-logo.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"},
    }, indent=2) + "\n", encoding="utf-8")

    # 4. Vorschau: Icon mit iOS-Maske, Marker hell/dunkel in Originalgrößen.
    rounded = Image.new("L", (1024, 1024), 0)
    ImageDraw.Draw(rounded).rounded_rectangle((0, 0, 1023, 1023), radius=229, fill=255)
    board = Image.new("RGB", (900, 400), (242, 242, 247))
    masked = Image.new("RGB", (1024, 1024), (242, 242, 247))
    masked.paste(icon, (0, 0), rounded)
    board.paste(masked.resize((360, 360), Image.LANCZOS), (20, 20))
    for background, colour, top in (((0, 0, 0), (255, 255, 255), 20), ((255, 255, 255), (0, 0, 0), 210)):
        board.paste(Image.new("RGB", (480, 170), background), (400, top))
        for width, left in ((92, 430), (29, 560), (200, 640)):
            scaled = mark.resize((width, round(mark.size[1] * width / mark.size[0])), Image.LANCZOS)
            board.paste(Image.new("RGB", scaled.size, colour), (left, top + 85 - scaled.size[1] // 2), scaled.split()[3])
    board.save(ART / "wave-brand-preview.png")


if __name__ == "__main__":
    main()
