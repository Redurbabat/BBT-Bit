# Designsystem

- Nutze [Theme.swift](../AppleApp/Sources/UI/Theme.swift) und [ArtworkPalette.swift](../AppleApp/Sources/UI/ArtworkPalette.swift) für semantische Farben und Cover-Akzente. Systemschrift und semantische Textstile skalieren mit Dynamic Type. Größere Textgrößen dürfen Layouts umordnen.
- Trenne Oberfläche, Inhalt und Bedienung. Glas unterstützt die Hierarchie und bleibt auf kontrastreichem oder wechselndem Artwork lesbar. Verfügbarkeit für iOS/macOS 26 prüfen und die bestehenden Fallbacks der älteren Zielsysteme verwenden. Reduce Transparency braucht eine lesbare Fläche.
- Motion braucht Auslöser, erkennbaren Ursprung und Ziel, einen unterbrechbaren Verlauf und einen stabilen Endzustand. Richtwerte aus dem UI-Kit sind 0,18–0,28 s für Feedback und 0,35–0,5 s für einen Morph. Vorhandene Kurven und Gesten haben Vorrang. Reduce Motion erhält dieselbe Bedienung mit einer ruhigeren Darstellung.
- **Verbindliches RED-Morph-iPhone-Verhalten:** Beim Scrollen nach unten minimiert die **native Tab-Leiste** und der **eine** Mini-Player wechselt als `tabViewBottomAccessory` in deren Inline-Modus; beim Hochscrollen klappen beide wieder gemeinsam auf. Das Pill ist zugleich Zoom-Quelle für den Vollplayer. Nicht mit einer festen `.tabBarMinimizeBehavior(.never)`-Regel, einer zusätzlichen Dock-Leiste oder einer abgetrennten Suche ersetzen. Details und Regression: [RED Morph](red-morph-player-search-navigation.md) · [Entscheidungen](../ENTSCHEIDUNGEN.md).
- Nutze [Glass Bloom](../AppleApp/Sources/UI/LiquidMotion/LogoGlassBloom.swift) für logoabhängige Zustände und [Cover Morph](../AppleApp/Sources/UI/NowPlaying/CoverMorphArtworkContext.swift) für den gemeinsamen Artwork-Kontext. Dauerlauf, Blur und Schatten brauchen einen konkreten Zweck. Prüfe Interaktion unter laufender Wiedergabe.
- iPhone-Treffflächen mindestens 44 × 44 pt. Gesten erhalten eine erreichbare Alternative. Prüfe VoiceOver-Labels, Fokus nach Präsentation und Rückkehr, Dynamic Type, Hell/Dunkel, Safe Areas, Rotation, iPad und macOS-Tastaturbedienung.
- Das [UI-Kit Motion Lab](https://github.com/Redurbabat/UI-Kit/blob/5e47ef79093626e5da6b78713ab071250ae2a611/docs/design/BBT_BIT_MOTION_LAB.md) beschreibt Interaktionen. BBT-Bit verwendet die vorhandene SwiftUI-Navigation und echte Playerzustände. Vorschauen kennzeichnen Beispieldaten.

## Sprache

- Deutsch ist die App-Vorgabe, solange keine Sprachwahl gespeichert ist. Die Auswahl „Gerätesprache“ folgt dem System. Gespeicherte Sprachen haben Vorrang.
- Pflege im [String-Katalog](../AppleApp/Resources/Localization/Localizable.xcstrings) zu neuen oder geänderten UI-Texten eine deutsche Fassung. Erhalte vorhandene Schlüssel, englische Quellwerte, Platzhalter und Übersetzungen. Das gilt auch für Fehlermeldungen, Dialoge und Accessibility-Labels.
- Prüfe den betroffenen Nutzerweg mit Deutsch und einer zweiten gespeicherten Sprache. Teste längere deutsche Texte mit großer Schrift. Musik- und Künstlernamen erscheinen wie von der Quelle geliefert.

## Neutrales Apple Liquid Glass für Music Island und Mini-Player

- **iPhone iOS 26+:** Die native `TabView.tabViewBottomAccessory` zeichnet die Glasfläche des Mini-Players. Keine zweite Kapsel mit Cover-Farbverlauf, Gradient, Border oder manuell gefärbtem Material darin.
- **iPad/macOS und appinterne Music Island:** Eine einzelne `.glassEffect(.regular, in: ...)`-Fläche für Bedienelemente. Ältere Systeme erhalten semantisches `.regularMaterial` als Fallback; Reduce Transparency oder `reduce_dynamic_blur` verwenden `Theme.Materials.opaque`.
- **Kontrolle:** Primäre/sekundäre Systemtextfarben statt weißer Schrift auf künstlichen Cover-Tints. Coverfarben bleiben im Albumcover und können den **Vollbildplayer** weiterhin gestalterisch begleiten, aber nicht die Navigation färben. Liquid-Glass-Highlights und Kontrast bestimmt das Betriebssystem.
- **Die Music Island über der App ist keine Hardware-Dynamic-Island/Live-Activity.** Sie enthält denselben `PlaybackController` und ändert nur ihre Darstellung, nicht den Audiozustand.

## BBT-Bit Testzentrale (E-012)

Die Testzentrale ist eine native SwiftUI-`Form` mit `Section`, `LabeledContent`, `Picker`, `NavigationLink` und `ShareLink`. Es gelten systemeigene semantische Textfarben, VoiceOver-Fokus und dynamische Schriftgrößen. Der Passivmonitor darf keine Playback-Transportbefehle senden; manuelle Testergebnisse bleiben ausdrücklich `Nicht getestet`, bis sie vom Nutzer markiert werden. Der datensparsame Bericht verlässt das iPhone nur nach einer eigenen ShareLink-Aktion. Siehe [Testplan](TESTPLAN.md#bbt-bit-testzentrale--native-live-diagnose).
- **Verbindliches RED-Morph-iPhone-Verhalten:** Beim Scrollen nach unten minimiert die **native Tab-Leiste** und der **eine** Mini-Player wechselt als `tabViewBottomAccessory` in deren Inline-Modus; beim Hochscrollen klappen beide wieder gemeinsam auf. Das Pill ist zugleich Zoom-Quelle für den Vollplayer. Nicht mit einer festen `.tabBarMinimizeBehavior(.never)`-Regel, einer zusätzlichen Dock-Leiste oder einer abgetrennten Suche ersetzen. Details und Regression: [RED Morph](red-morph-player-search-navigation.md) · [Entscheidungen](../ENTSCHEIDUNGEN.md).
