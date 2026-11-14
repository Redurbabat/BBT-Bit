# BBT-Bit: IPA für iPhone und iPad mit Codemagic

Im Repo-Verzeichnis liegt `codemagic.yaml`. Es definiert den manuellen Workflow
**BBT-Bit — iPhone/iPad unsigned IPA** (`bbt-bit-ios-ipa`).

## Auf deinem iPhone oder iPad starten

1. Öffne [codemagic.io](https://codemagic.io/) und melde dich über GitHub an.
2. Füge das GitHub-Repository **Redurbabat/RED-Bit** in Codemagic hinzu.
3. Wähle das Repository und den Zweig **main** aus. Lass Codemagic die Datei
   `codemagic.yaml` im Repository-Stammverzeichnis erkennen; falls erforderlich
   klicke auf **Check for configuration file**.
4. Wähle **BBT-Bit — iPhone/iPad unsigned IPA** und starte **Start new build**.
5. Bei einem erfolgreichen Build öffne die Build-Detailseite und lade unter
   **Artifacts** eine Datei wie `BBT-Bit-1.0.4-build13-ios-unsigned.ipa` herunter.

Der Workflow kompiliert eine native SwiftUI-Anwendung mit Kotlin/Native und Rust:
- Codemagic Mac mini M2, Xcode 26.0, Java 21
- installiert/prüft XcodeGen, CMake und Rust;
- kompiliert `RedBitShared.xcframework` im Release-Modus (interner Modulname);
- kompiliert Rust `NativeCoreFFI.xcframework`;
- erzeugt das Xcode-Projekt mit XcodeGen;
- archiviert eine iOS/iPadOS-App **ohne Signierung** und verpackt sie als IPA;
- prüft App-Kennung `com.babat.bbtbit` und sichtbaren Namen `BBT-Bit`.

## WICHTIG: unsigniert ist nicht direkt installierbar

Diese Datei ist **nicht** mit einem Apple-Entwicklerzertifikat signiert. Sie ist
für eine nachfolgende rechtmäßige Signierung geeignet, z. B. mit deinem eigenen
Apple-Konto und einem geeigneten Sideloading-Tool bzw. einer Developer-Signatur.
Das reine Herunterladen oder Antippen der IPA installiert sie nicht auf dem
iPhone/iPad. Ein kostenloses Apple-Konto hat Signatur- und Laufzeitgrenzen.
Codemagic erzeugt hier **keine** automatisch installierbare App, und die
Konfiguration enthält bewusst keine privaten Zertifikate oder Passwörter.

## Fehlersuche

Das erste Kompilieren kann auf dem 12-GB-Mac-Mini sehr zeitaufwendig sein. Falls
Codemagic abbricht, öffne den fehlerhaften Schritt und prüfe die Ausgabe von
Gradle, Cargo, XcodeGen oder xcodebuild. Maximaldauer: 120 Minuten.
Dieses Workflow-Rezept wurde eingerichtet, **aber noch nicht auf Codemagic
ausgeführt oder durch einen echten IPA-Download bestätigt**.

Die Paketdatei heißt BBT-Bit, obwohl das intern bewahrte Xcode-Schema und das
ausgelieferte App-Verzeichnis `RED Bit.app` heißen. Ausschlaggebend für die
Anzeige auf dem Gerät ist die `CFBundleDisplayName` `BBT-Bit`. Die Original-Lizenzen
und Quellennachweise bleiben erhalten.

Codemagic-Hilfe:
- https://docs.codemagic.io/getting-started/adding-apps/
- https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
- https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/
