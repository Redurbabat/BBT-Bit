# RED Bit – Logo

## Aktuell: Wellen-Logo des Nutzers (11. November 2026)

Vom Nutzer gelieferter Entwurf: cremefarbene, plastisch gedrehte Klangwelle zwischen zwei Punkten auf Bordeaux. [Vorschau](wave-brand-preview.png). App-Icon, Icon-Composer-Ebene (iOS/macOS 26) und In-App-Marker (Toolbar, Onboarding, Konto, Glass Bloom) verwenden dieselbe Quelle. Asset-Namen und Bundle-IDs bleiben unverändert; die Datenpfade heißen seit [E-024](../../ENTSCHEIDUNGEN.md) `RedBit`.

| Datei | Zweck |
| --- | --- |
| [wave-source.webp](wave-source.webp) | Originaldatei des Nutzers |
| [wave-icon-1024.png](wave-icon-1024.png) | Randloses Legacy-Icon 1024 × 1024 RGB ohne Alpha; Ecken außerhalb des Quadrats glatt aufgefüllt, iOS maskiert selbst |
| [wave-glyph.png](wave-glyph.png) | Freigestellte, schattierte Welle; Ebene `wave.png` im Icon-Composer-Paket über einem Bordeaux-Verlauf |
| [wave-mark.png](wave-mark.png) | Template-Marker: Deckkraft folgt der Helligkeit, damit die Drehung auch klein lesbar bleibt |
| [wave-brand-preview.png](wave-brand-preview.png) | Sichtprüfung: Icon mit iOS-Maske, Marker in 92, 29 und 200 pt auf Dunkel/Hell |

Reproduzierbar erzeugen (Pillow und NumPy, nur lokal): `python scripts/render-red-bit-wave-logo.py`. Das ältere `scripts/render-red-bit-brand.py` würde wieder den Signalband-Entwurf schreiben und ist nur noch historisch. Icon Composer in Xcode, Hell/Dunkel/Getönt auf echtem iPhone und Mac: **NICHT GETESTET**.

## Historisch: Signalband-Entwurf vom 8. November 2026

Der aktuelle Integrationsbranch verwendet ein eigenes geöffnetes R als Signalband. Der seitliche Einschnitt verbindet die Wortmarke mit einem unterbrochenen digitalen Signal; die breite, ruhige Form bleibt als Toolbar-Marker lesbar. Warmes Rot (`#FF5A42`, `#D62236`, `#7C1028`) und gebrochenes Weiß (`#FFF9F0`) prägen das App-Icon. Der Template-Marker folgt der Systemfarbe. Der frühere REC-Entwurf bleibt unten als historische Quelle erhalten.

| Aktuelle Datei | Zweck |
| --- | --- |
| [signal-mark.svg](signal-mark.svg) | Kanonische eigene Pfadgeometrie, 100 × 100 |
| [signal-glyph.svg](signal-glyph.svg) | Ebene des bestehenden Icon-Composer-Pakets |
| [signal-icon.svg](signal-icon.svg) | Opaques Icon mit Rotverlauf |
| [signal-icon-1024.png](signal-icon-1024.png) | 1024 × 1024 RGB ohne Alpha; identisch zum Legacy-App-Icon |
| [signal-brand-preview.png](signal-brand-preview.png) | Visuelle Prüfung von großem Icon und kleinen hellen/dunklen Markern |

Reproduzierbar erzeugen:

```powershell
python -m pip install --target build/brand-tools resvg-py==0.5.0 Pillow==13.0.0
python scripts/render-red-bit-brand.py
```

Eigener Entwurf für dieses Projekt, keine fremden Marken- oder Bilddateien übernommen. Rendering: [resvg-py](https://github.com/baseplate-admin/resvg-py) (MIT), [Pillow](https://github.com/python-pillow/Pillow) (MIT-CMU), ausschließlich lokale Entwicklungswerkzeuge. Lizenzen und Herkunft wurden in den installierten Wheel-Metadaten bzw. deren `licenses/LICENSE` geprüft. Das Skript kopiert die kanonische Geometrie in die bestehenden Asset-Pfade und lässt deren Namen unverändert. Das Vorschau-Board verwendet die lokale Systemschrift; die App bekommt keine neue Schriftabhängigkeit. Icon Composer und das neue Icon im echten iPhone-/Mac-Build: **NICHT GETESTET** bis zur Plattformabnahme.

## Historischer REC-Entwurf

Ein fettes **R** mit leuchtendem **REC-Punkt** im Bogen. Der Punkt steht für „RED“, für die Aufnahmetaste und für die Spindel einer Schallplatte. Der Verlauf von hellem Rot zu fast schwarzem Rot passt zum RED-Morph-Look der App (schwarzer Grund, rote Akzente).

| Datei | Zweck |
| --- | --- |
| [icon.svg](icon.svg) | Vollbild-Icon mit Verlauf, Quelle für `icon-1024.png` |
| [icon-1024.png](icon-1024.png) | Raster-Vorschau, ohne Alpha als Legacy-Icon in `AppIcon.appiconset` |
| [glyph.svg](glyph.svg) | Weißes R plus Punkt ohne Hintergrund, Ebene im Icon-Composer-Paket `AppleApp/AppIcon.icon` (Verlauf liegt in `icon.json`) |
| [mark.svg](mark.svg) | Einfarbiger Marker aus gefüllten Formen für `bch-logo` (Template-Rendering, Onboarding, Konto-Sheet, Glass Bloom) |
| [variants/pixel-r.svg](variants/pixel-r.svg) | Verworfene Variante: R aus „Bits“ auf Pixelraster; bleibt als Reserve für Aktionen oder Aufkleber |

## Warum dieser Entwurf

- **Lesbar klein:** bis 40 px erkennbar. Das Pixel-R wurde verworfen, weil die Zwischenräume bei kleinen Größen verschwimmen.
- **Eine Idee:** Der Punkt ist das einzige Detail; kein zweites Symbol konkurriert damit.
- **Icon Composer:** Eine Glasebene und ein Verlauf, wie beim vorherigen Paket. Dadurch bleibt die Struktur von `icon.json` unverändert.

## Neu erzeugen

```bash
rsvg-convert -w 1024 -h 1024 artwork/red-bit/icon.svg -o artwork/red-bit/icon-1024.png
python3 -c "from PIL import Image; Image.open('artwork/red-bit/icon-1024.png').convert('RGB').save('AppleApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png')"
```

**Nicht getestet:** Das Icon-Composer-Paket wurde ohne Xcode erstellt. Vor einer Auslieferung in Xcode öffnen und Hell, Dunkel und Getönt ansehen.
