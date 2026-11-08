# RED Bit – Logo

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
