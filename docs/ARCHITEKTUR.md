# BBT-Bit · Architektur

## Verantwortungsbereiche

| Bereich | Einstieg | Aufgabe |
| --- | --- | --- |
| Swift App | [BitChordApp](../AppleApp/Sources/App/BitChordApp.swift), [RootView](../AppleApp/Sources/UI/RootView.swift) | Lebenszyklus, Dienste, Tabs und Settings. |
| Wiedergabesitzung | [PlaybackController](../AppleApp/Sources/PlaybackSession/PlaybackController.swift) und [Erweiterungen](../AppleApp/Sources/PlaybackSession/) | Queue, Transport, Laden, Recovery, Zeitfortschritt, Routen und UI-Zustand. Mini- und Vollplayer lesen dieselbe Sitzung. |
| Resolver | [InnertubeStreamResolver](../AppleApp/Sources/App/InnertubeStreamResolver.swift), [SourceResolution](../AppleApp/Sources/PlaybackSession/PlaybackController%2BSourceResolution.swift) | Kandidaten bestimmen und verifizieren, Fehlertypen und Fallback an die Sitzung melden. |
| Kotlin Multiplatform | [shared](../shared/), [InnerTubeX](../vendor/innertubex/), [Gradle-Graph](../settings.gradle.kts) | Shared-API, Konto, HTTP, Stream-/Metadatenlogik und Persistenz. `:shared` verwendet `:innertubex`. Darwin-spezifische Implementierungen liegen in `appleMain`. |
| Audio-Engine | [Native API](../native-core/src/api.rs), [Decode](../native-core/src/decode/), [Mixer](../native-core/src/mixer/), [Output](../native-core/src/output.rs) | Decode, Buffer, DSP, Mixer, Ausgabe, Analysen und Callbacks an Swift. |
| Widget | [BitChordWidget](../AppleApp/Sources/Widget/), [NowPlayingActivityAttributes](../AppleApp/Sources/Shared/NowPlayingActivityAttributes.swift) | Separates Target. Austausch über App Group und Activity-Daten. |

## Abhängigkeitsgrenzen

- [XcodeGen](../AppleApp/project.yml) beschreibt das App- und Widget-Target. Swift-App-Code verwendet `BitChordShared.xcframework` und die generierten Swift-Bindings über `NativeCoreFFI.xcframework`. Kotlin und Rust sind auf der Apple-Seite getrennte Build-Eingaben. Das Widget bleibt von beiden nativen Frameworks entkoppelt.
- [Kotlin-Build](../scripts/build-shared-framework.sh) und [Rust-Build](../scripts/build-native-core.sh) erzeugen die nativen Artefakte. Erzeuge sie neu, wenn sich Kotlin-Exports, das UniFFI-API oder eine Zielarchitektur ändern. Generierte Dateien gehören in den Build-Ausgabepfad.
- UI, App und PlaybackSession sind Swift-Ordner im selben Target. Neue Netzwerk- und Engine-Entscheidungen gehören zu Resolver bzw. Sitzung. Views nutzen deren Zustände und Aktionen. Entkopplung innerhalb des Targets bleibt ein Review-Thema.
- Verändere bei Schnittstellenarbeit Fehler, Cancellation, Callback-Reihenfolge und Plattformvarianten gemeinsam. Siehe [Testplan](TESTPLAN.md) für die Nachweise an den Übergängen.
