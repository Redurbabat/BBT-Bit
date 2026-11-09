# RED Bit

RED Bit (ehemals BBT-Bit) ist eine eigenständig gepflegte native Musik-App für iPhone, iPad und Apple-Silicon-Macs aus der BABAT-Appfamilie.

Die Grundlage ist der offene BitChord-Apple-Port von Martin BAGUMA, der auf BitChord von Kushagra Singh basiert. RED Bit ist eine eigenständige Weiterentwicklung. Herkunft und Lizenzen bleiben erhalten.

## Projekt und Kompatibilität

- Repository und Quellcode: https://github.com/Redurbabat/RED-Bit
- Anzeigename: RED Bit. Die App-ID `com.babat.bbtbit`, das URL-Schema `bbtbit://`, Datenordner und interne Dateinamen bleiben für bestehende RED-/BBT-Bit-Installationen erhalten.
- Widget-ID: `com.babat.bbtbit.widget`. Keychain und App Group verwenden eigene BBT-Bit-Namensräume.
- SwiftUI zeigt die Oberfläche; Kotlin Multiplatform bündelt Daten und Netzwerk; Rust stellt die Audioengine bereit. Interne BitChord-Modulnamen erhalten die Build-Kompatibilität.
- Optionale Automix-Modelle stammen aus den öffentlichen BitChord-Apple-Modellreleases und werden anhand festgelegter SHA-256-Prüfsummen geprüft. Sie sind nicht in der App gebündelt.
- Externe Dienste wie YouTube Music bleiben von ihren jeweiligen Anbietern abhängig.

## Übernommene Original-Funktionen

PR #59 ergänzt Addon-Autoplay mit geprüftem YouTube-Startpunkt, einen Titelwechsel innerhalb der laufenden Mischung, gemessene Automix-Wellenformen und einen optionalen Abgleich von Offline-Playlists. [Umsetzung, Herkunft und Prüfgrenzen](docs/ORIGINAL_PARITAET_PR59.md).

Der Playlist-Abgleich läuft bei aktiver App und holt fällige Prüfungen beim Öffnen nach. Er respektiert die WLAN-Regel und bewusste Löschungen. Bei älteren Download-Indizes setzt der erste vollständige Abgleich zunächst eine sichere Ausgangsliste.

## Bauen und aktualisieren

Erforderlich sind ein Mac mit Xcode, XcodeGen, JDK, Rust, CMake und Zugriff auf die Abhängigkeiten. Die [ursprüngliche Bauanleitung](docs/ORIGINAL_BITCHORD_README.md) beschreibt die Werkzeuge; zu klonen ist `Redurbabat/RED-Bit`. Xcode-Projekt und Scheme heißen intern weiterhin BitChord; die installierte App heißt RED Bit.

Die Updateprüfung verwendet ausschließlich RED-Bit-Veröffentlichungen. Das private GitHub-Repository liefert der anonymen App keine Releases; die App benennt diese Grenze und bietet die Release-Seite im Browser an. Automatische Mac-Updates bleiben bis zu einem eigenen konfigurierten Signatur-Feed deaktiviert.

Ein RED-Bit-App-Installer wurde noch nicht veröffentlicht. Für eine Auslieferung sind passende Signierung, Paketprüfung und ein Gerätetest erforderlich. Von einer ursprünglichen BitChord-Installation findet keine automatische Datenmigration statt. [Release-Ablauf](docs/RELEASE.md).

## Mitwirken

[Einstieg](AI_START_HERE.md) · [Architektur](docs/ARCHITEKTUR.md) · [Skills und Arbeitsablauf](docs/AGENT_WORKFLOW.md) · [Testplan](docs/TESTPLAN.md).

## Herkunft und Lizenzen

Die Software bleibt, soweit anwendbar, GPLv3. Copyright und ursprüngliche Zuschreibungen sind in [LICENSE](LICENSE), [Lizenztexten](LICENSES/), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), Dateiheadern und der [ursprünglichen README](docs/ORIGINAL_BITCHORD_README.md) erhalten. Diese Hinweise gehören auch zu weitergegebenen Builds.

RED Bit ist nicht mit Google oder YouTube verbunden und wird von diesen nicht unterstützt. Die Verfügbarkeit externer Musikdienste liegt bei den jeweiligen Anbietern.
