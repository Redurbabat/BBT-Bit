# Releases

## Version und Build

[AppleApp/project.yml](../AppleApp/project.yml) liefert `MARKETING_VERSION` und `CURRENT_PROJECT_VERSION` für App und Widget. Beide Plists referenzieren die Xcode-Einstellungen. Das [Metadatenpaar](../version.md) muss denselben Stand führen. Cargo-, Gradle- und Modellversionen haben eigene Zwecke.

`candidate` steht für Entwicklung und Prüfung. `published` setzt dokumentierte Freigabe, passendes Tag, Artefaktidentität und tatsächliche Veröffentlichung voraus. Nur der Maintainer veranlasst die Veröffentlichung. Die Repo-Prüfung vergleicht lokale Werte und prüft bei `published` einen verzeichneten Release-Link. Der Nachweis der Auslieferung erfolgt separat.

## Bauen und prüfen

Der getrennte [SideStore-Gerätetest](IPHONE_TESTSYSTEM.md) erzeugt eine unsignierte iOS-Testvariante ohne Widget und iCloud-Freigaben. Er verwendet die vorhandenen Bauskripte, veröffentlicht kein Release und ersetzt weder die Geräteabnahme noch den unveränderten Codemagic-/Release-Ablauf.

1. Auf Apple Silicon die vorhandenen [Framework-Skripte](ARCHITEKTUR.md#abhängigkeitsgrenzen) ausführen und das Projekt mit `xcodegen generate --spec AppleApp/project.yml` generieren.
2. [Codemagic](../CODEMAGIC-IOS.md) verwendet Java 21, Xcode 26 und die vorhandenen Caches. `bbt-bit-ios-fast-ipa` baut einen unsignierten Debug-IPA bei passenden PRs. `bbt-bit-ios-ipa` archiviert einen unsignierten Release-IPA auf manuellen Start. [Simulator-Actions](github-iphone-simulator-tests.md) liefert Testbelege.
3. Beide Apple-Artefakte aus demselben sauberen Commit bauen. Die konkreten Schritte stehen in [APPLE_RELEASES.md](../APPLE_RELEASES.md). `prepare-apple-release.py` liest die Plists der Artefakte und erzeugt `release.json`, `SHA256.txt` und `INSTALL.md`. Prüfe Version, Build, Bundle-ID und Commit gegen den Kandidaten.
4. Für eine Installation auf dem iPhone mit passendem Team, Entitlements und Profil signieren. Installierbarkeit, Update einer bestehenden Installation, Datenbestand und Wiedergabe am Gerät prüfen. Für macOS den bestehenden [Signier- und Sparkle-Ablauf](../MAC_RELEASE.md) und [Feed](../MAC_AUTO_UPDATES.md) verwenden.
5. Freigabe, signierte bzw. vorgesehene Artefakte, Prüfsummen, Commit, Geräteprüfung und Status im Versionsverlauf festhalten. Frühere Feedeinträge bleiben historische Releases.

Der getrennte [SideStore-Gerätetest](IPHONE_TESTSYSTEM.md) erzeugt eine unsignierte iOS-Testvariante ohne Widget und iCloud-Freigaben. Er verwendet die vorhandenen Bauskripte, veröffentlicht kein Release und ersetzt weder die Geräteabnahme noch den unveränderten Codemagic-/Release-Ablauf.
