# BBT-Bit auf dem iPhone testen

Stand: 10. November 2026. Zielgerät: iPhone 13 Pro Max mit iOS 26 oder neuer.

## Was vorbereitet ist

Der Ablauf lautet **GitHub-Branch → macOS-Runner → unsignierte Geräte-IPA → Download auf das iPhone → Signierung und Installation mit SideStore**. Der [Workflow](../.github/workflows/ios-sidestore-test.yml) heißt **BBT-Bit iPhone-Testversion**. Er verwendet die vorhandenen Kotlin-, Rust- und IPA-Bauskripte. Die Codemagic-Workflows bleiben erhalten.

Eine unsignierte IPA ist noch nicht installierbar. SideStore muss mit deinem Apple-Konto ein gültiges Geräteprofil und eine Signatur erzeugen. Die Paketprüfung erkennt die Gerätearchitektur, eingebettete Revision, fehlende Frameworks, Simulator-Binaries und verschlüsselte App-Store-Binaries. Sie beweist keine erfolgreiche Signierung oder Installation.

**Prüfstand vom 10. November:** Der Gerätebau für PR #59 wurde [hier gestartet](https://github.com/Redurbabat/RED-Bit/actions/runs/42715735687) und führt tatsächlich native Buildschritte aus. Frühere Läufe wurden vom Actions-Budget blockiert; diese älteren Sperren sind kein Ergebnis des neuen Baus. Ein IPA-Link gilt erst nach tatsächlich erfolgreichem Paketbau und Upload. Signierung, Installation, Datenerhalt und hörbares Audio bleiben getrennte Abnahmen.

## Kosten und automatische Branch-Auswahl

Private Repositories verbrauchen bei GitHub ihr enthaltenes Rechenkontingent; auch Artefakte und Caches haben Speichergrenzen. Ein kostenloses Apple-Konto macht den Cloud-Bau nicht automatisch kostenlos. Prüfe im GitHub-Konto **Settings → Billing and licensing → Budgets and alerts** das vorhandene Kontingent und behalte ein Ausgabenlimit, das zu deinem Wunsch nach kostenlosen Tests passt. Der Workflow verwendet einen Standard-Runner und erhöht kein Budget. [GitHub-Abrechnung](https://docs.github.com/en/billing/concepts/product-billing/github-actions)

Unter **Repository → Settings → Secrets and variables → Actions → Variables** steuern zwei gewöhnliche, nicht geheime Variablen den Automatismus:

| Variable | Bedeutung |
| --- | --- |
| `BBT_IOS_TEST_BRANCH` | Genau ein gewählter Branch, beispielsweise `main` nach der PR-Übernahme. |
| `BBT_IOS_TEST_AUTO_BUILD` | `true` aktiviert Builds bei relevanten Änderungen auf diesem Branch. Jeder andere Wert deaktiviert automatische Builds. |

Der neueste Push ersetzt einen noch laufenden Bau desselben Branches. Andere Agentenbranches werden dadurch nicht automatisch teuer gebaut. Die Dateien stehen nur drei Tage als Artefakt bereit. Lade eine benötigte IPA rechtzeitig herunter. Vorhandene zusätzliche PR- und Codemagic-Prüfungen können weiterhin ihr eigenes Kontingent verbrauchen.

Für die Arbeit an PR #59 wurde der vorhandene Automatismus am 10. November auf `BBT_IOS_TEST_BRANCH=codex/red-bit-integration-motion-20261108` und `BBT_IOS_TEST_AUTO_BUILD=true` ausgerichtet. Relevante Pushes dieses Branches starten damit den Gerätebau zusätzlich zu den PR-Prüfungen. Andere Agentenbranches bleiben unberührt. Nach einem später ausdrücklich freigegebenen Merge kann der Maintainer den ausgewählten Testbranch wieder auf `main` setzen. Ausgabenlimits und die normalen Release-/Codemagic-Abläufe werden dabei nicht verändert.

Der GitHub-Button für `workflow_dispatch` erscheint regulär, sobald der Workflow im Standardbranch liegt. Bis dahin bleibt der neue PR zur Prüfung offen. Ein Merge ist eine Entscheidung des Maintainers.

## Kostenloses Apple-Konto und BBT-Bit-Funktionen

Mit einem kostenlosen Konto gelten grundsätzlich sieben Tage Profilgültigkeit, höchstens drei gleichzeitig installierte Entwicklungs-Apps pro Gerät und zehn registrierbare App-IDs innerhalb von sieben Tagen. SideStore selbst belegt einen der drei App-Plätze. Erweiterungen benötigen zusätzliche App-IDs. Mit SideStore, BBT-Bit und später Redion wären die drei Plätze belegt. [Apple-Kontogrenzen](https://developer.apple.com/help/account/basics/about-your-developer-account) · [SideStore-FAQ](https://docs.sidestore.io/docs/faq)

Das normale BBT-Bit-Projekt verlangt iCloud-KVS und eine App Group mit Widget. Die separate Testkonfiguration erzeugt eine App **ohne Widget, App-Group-Freigabe und iCloud-Synchronisierung**. Sie vermeidet diese zusätzlichen Provisioning-Anforderungen. Musikplayer, native Decoder, Streaming-Code, Playlists und lokale Datenformate werden dafür nicht umgeschrieben. Die normale [XcodeGen-Datei](../AppleApp/project.yml) und der Release-Bau bleiben bestehen. Die Testvariante ersetzt keinen Test der iCloud- oder Widget-Funktionen.

Die Quell-Bundle-ID bleibt **`com.babat.bbtbit`**, das URL-Schema `bbtbit`. Die Marketingversion und Buildnummer stammen weiterhin aus dem Projekt. Dateiname und `build.json` ergänzen vollständigen Commit, Quellbranch, Workflow-Lauf und SHA-256-Prüfsumme. SideStore kann beim Signieren eine kontobezogene Kennung verwenden. Verwende bei Updates dasselbe Apple-Konto, dieselbe App und dieselbe SideStore-Zuordnung.

## Einmalige Einrichtung unter Windows 10/11

1. Verwende ein unterstütztes 64-Bit-Windows. Lade Apple-iTunes aus dem offiziellen Apple-Angebot oder Microsoft Store. Die aktuelle SideStore-Anleitung empfiehlt die Apple-Version; falls die Geräteverbindung damit scheitert, nennt sie Apple Devices als Alternative.
2. Lade **iloader** ausschließlich über die in der [offiziellen Vorbereitung](https://docs.sidestore.io/docs/installation/prerequisites) verlinkte Projektseite. Installiere den passenden Windows-Installer. Installiere auf dem iPhone die dort verlinkte App **LocalDevVPN** aus dem App Store.
3. Verbinde das entsperrte iPhone per USB. Bestätige auf dem iPhone das Vertrauen zum PC.
4. Öffne iloader, melde dich mit deinem kostenlosen Apple-Konto an, wähle das iPhone und **Install SideStore (Stable)**. Bestätige eine vom Programm verlangte Kontoprüfung selbst. Zugangsdaten und Geräte-Pairing-Dateien gehören ausschließlich auf deine Geräte, niemals in GitHub, CI-Variablen oder einen Chat.
5. Folge auf dem iPhone unter **Einstellungen → Allgemein → VPN und Geräteverwaltung** dem Eintrag deines Entwicklerkontos. Unter iOS 26 kann die Freigabe einen Neustart verlangen.
6. Aktiviere **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus** und bestätige den Neustart sowie die anschließende Abfrage.
7. Öffne LocalDevVPN, erlaube die VPN-Konfiguration und verbinde sie. Verbinde das iPhone zusätzlich mit WLAN.
8. Öffne SideStore und verwende dasselbe Apple-Konto wie in iloader. Unter **My Apps** erneuerst du zuerst SideStore über den Tageszähler. Bestätige gegebenenfalls die vom Programm erforderliche Zertifikatsanlage.

Die Schritte folgen der aktuellen [SideStore-Installationsanleitung](https://docs.sidestore.io/docs/installation/install). Im normalen Betrieb genügt danach das iPhone. Nach einem iOS-Update, verlorenem Pairing oder abgelaufenem SideStore kann erneut ein PC erforderlich sein; ein dauerhaft wartungsfreier Betrieb ohne jede Wiederherstellung ist nicht garantiert.

## Neue Testversion auf GitHub bauen

Erfolgreiche neue Läufe verlinken das tatsächlich hochgeladene IPA-Paket zusätzlich direkt in ihrer Zusammenfassung unter **iPhone-Testpaket herunterladen**. Der Link zeigt auf das GitHub-Artefakt des jeweiligen Laufs; Anmeldung und die bestehende Aufbewahrung von drei Tagen gelten weiterhin. Das Paket enthält die unsignierte IPA samt `build.json`, Prüfsumme und Installationshinweis. Es wird kein öffentlicher Release und keine Apple-Signatur erzeugt.

Der Geräteworkflow sichert native Zwischenergebnisse auch nach einem späteren App- oder Paketfehler. Ein eigener Cache-Schlüssel pro Lauf ermöglicht das Speichern aktualisierter Framework-Archive; das bestehende Cache-Skript prüft vor jeder Nutzung weiterhin Quellen, Toolchain-Fingerabdruck und Prüfsummen. Ein Cache-Treffer ersetzt keinen App-Build und keinen Paketnachweis. Abgebrochene Läufe speichern keine neuen Caches.

Automatisch: Nach der Freigabe des PRs und gesetzten Variablen genügt ein Push mit App- oder Buildänderungen auf den gewählten Branch. Agenten arbeiten weiter auf ihren eigenen Branches; der Maintainer übernimmt die gewünschte Änderung in den gewählten Testbranch.

Manuell auf dem iPhone:

1. Öffne [GitHub Actions von BBT-Bit](https://github.com/Redurbabat/RED-Bit/actions) in Safari und melde dich an. Verwende bei Bedarf die Desktopansicht.
2. Wähle **BBT-Bit iPhone-Testversion → Run workflow**.
3. Wähle einen Branch, der die Workflow-Datei enthält. Das Feld `source_ref` darf einen anderen App-Branch oder vollständigen Commit **desselben Repositorys** enthalten, beispielsweise den Head eines Agenten-PRs. Leer bedeutet den ausgewählten Workflow-Branch.
4. Starte den Lauf. Die Werkzeuge kommen aus dem Workflow-Stand, die App aus dem gewählten Quellstand. Der Bericht nennt beide nachvollziehbar über Lauf und Quellrevision.
5. Nur wenn der Bau und die Paketprüfung erfolgreich sind, erscheint unter **Artifacts** ein Paket `BBT-Bit-VERSION-buildBUILD-BRANCH-SHA-LAUF`. Ein fehlgeschlagener oder wegen Budget gesperrter Lauf enthält keine neue IPA.

## IPA herunterladen und erstmals installieren

**Prüferkorrektur vom 9. November 2026 (PR #59):** Der Paketprüfer liest jetzt `LC_RPATH`, löst `@rpath`, `@loader_path` und `@executable_path` innerhalb des App-Pakets auf und prüft abhängige Bibliotheken weiter. So darf Xcodes `RedBit.debug.dylib` direkt neben dem App-Programm liegen, wenn ein deklarierter Laufzeitpfad dorthin zeigt. Die frühere feste `Frameworks/`-Annahme konnte eine gültige Struktur ablehnen. 21 künstliche Paket-/Konfigurationsfälle bestehen; das ist noch kein Nachweis für eine neu erzeugte IPA oder SideStore-Installation. [Details und Grenzen](RED_BIT_INTEGRATION.md#paket--und-reader-korrektur-vom-9-november-2026).

1. Lade das Artefakt auf der erfolgreichen Run-Seite in Safari herunter. Das private Repository verlangt eine GitHub-Anmeldung; eine öffentliche SideStore-Quelle wird nicht eingerichtet.
2. Öffne **Dateien → Downloads** und entpacke das äußere Artefakt-ZIP. Im Ordner liegen `.ipa`, `build.json`, `SHA256.txt` und `INSTALLIEREN.txt`. **Die IPA selbst nicht entpacken.**
3. Kontrolliere Branch und Commit in `build.json` gegen den gewünschten PR. Eine Prüfsumme sichert die heruntergeladene Datei, sie ersetzt keine gültige Apple-Signatur.
4. Aktiviere WLAN und LocalDevVPN. Öffne SideStore, dann **My Apps → +**, und wähle die IPA aus Dateien. SideStore übernimmt Signierung und Installation auf deinem Gerät.
5. Erst nach erfolgreichem Abschluss öffnest du BBT-Bit. Notiere die Quellrevision und prüfe Musikstart, fortschreitende Zeit und hörbaren Ton. Bei einem Signing-Fehler sichere dessen Wortlaut; ein erfolgreicher Cloud-Bau bedeutet noch keine erfolgreiche Installation.

## Vorhandene Installation aktualisieren

**BBT-Bit nicht löschen.** Sichere vor der ersten Umstellung wichtige Daten. Der vorhandene Menüpunkt **Export Data** exportiert Einstellungen und Hörverlauf, aber keine vollständige Sicherung aller Playlists, Offline-Audiodateien oder Schlüsselbunddaten. Sichere wichtige Musikdateien zusätzlich über Dateien beziehungsweise deinen vorhandenen Exportweg.

Lade die nächste IPA desselben Projekts herunter und wähle sie erneut über **+** in derselben SideStore-Installation. Bei gleichbleibendem Konto und derselben Signierzuordnung sollte sie die vorhandene App aktualisieren. Die tatsächliche Erhaltung der Daten ist **NICHT GETESTET**. Falls SideStore eine zweite App anlegt, eine andere Kennung oder eine Löschung verlangt, stoppe den Vorgang und kläre die Identität, bevor du fortfährst. Ein Wechsel von Signierteam, alter Bundle-ID oder Distributionsart ist kein nachgewiesen sicheres Update.

Vergleiche nach einem ersten erfolgreichen Update Playlist-Anzahl, Einstellungen, Hörverlauf, heruntergeladene Titel und einen lokalen Offline-Titel mit dem vorherigen Stand. Prüfe danach Anmeldung, Streaming, Hintergrund und Bluetooth. So wird aus einem installierten Paket ein belegter Anwendungstest.

## Vor Ablauf der sieben Tage erneuern

Aktiviere WLAN und LocalDevVPN und verwende in SideStore **My Apps → Refresh All**, bevor der Tageszähler abläuft. Erneuere auch SideStore selbst. Eine neue GitHub-Version ist für das reine Erneuern der Signatur nicht nötig. Hintergrund-Erneuerung kann helfen, ihre rechtzeitige Ausführung durch iOS ist aber nicht garantiert. Prüfe den Zähler regelmäßig. Ist nur BBT-Bit abgelaufen, kann ein noch funktionierendes SideStore es erneut signieren. Ist SideStore selbst nicht mehr startbar, nutze den offiziellen Wiederherstellungsweg mit iloader. [SideStore-FAQ](https://docs.sidestore.io/docs/faq)

## Prüfstand dieses Auftrags

| Stufe | Nachweis |
| --- | --- |
| Vorhandenes Projekt und PRs | `main` auf `c2cf0a9`, PR #48 übernommen; #49 und #50 sind unabhängige offene Drafts. Kein bestehender PR für dieses Testsystem. |
| Paket- und Konfigurationsprüfung | `python scripts/ios-test-verify/check.py`: acht bestandene Tests mit künstlichen Paketen. Gegenproben für Simulator, Verschlüsselung, fehlende Binary/Frameworks, falsche Identität, fremde Profile, Erweiterungen und ZIP-Pfade. |
| Workflow-YAML | Mit Actionlint geprüft. |
| Swift/Kotlin/Rust-Gerätebau | **NICHT GETESTET** für diesen Workflow. Der macOS-Lauf wird aktuell durch das GitHub-Actions-Budget verhindert. Auf dem Windows-Rechner ist kein Apple-SDK vorhanden. |
| Tatsächlich erzeugte Test-IPA | **NICHT GETESTET**, kein echtes Artefakt vorhanden. Fixture-IPA-Dateien sind keine App. |
| SideStore-Signierung und Installation auf iOS 26 | **NICHT GETESTET**. Die Strukturprüfung ist eine Vorprüfung für die nachfolgende Signierung. |
| Update und Datenerhalt | **NICHT GETESTET** am iPhone. |
| Audio | **NICHT GETESTET** in dieser Testvariante. [Geräte-Testplan](TESTPLAN.md#echtes-iphone) |

Noch erforderlich sind die PR-Freigabe, ein nutzbares Cloud-Kontingent, die einmalige SideStore-Einrichtung, ein echter erfolgreicher Gerätebau und die anschließend dokumentierte Signierung, Installation und Updateprüfung. Die Budget-Blockade ist kein Compilerfehler.

## Später auf Redion übertragen

Read-only-Prüfung von `Redurbabat/Redion` auf Revision `371fcf7e50719793db5b58eec2d29ae7fe82bde4`: Redion enthält bereits [Capacitor-Konfiguration](https://github.com/Redurbabat/Redion/blob/371fcf7e50719793db5b58eec2d29ae7fe82bde4/capacitor.config.json), einen [iOS-IPA-Workflow](https://github.com/Redurbabat/Redion/blob/371fcf7e50719793db5b58eec2d29ae7fe82bde4/.github/workflows/ios-ipa.yml), native Swift-Adapter sowie Share- und Widget-Vorlagen. Die App-ID lautet `ch.redurbabat.redion`. Ein erfolgreicher Redion-Gerätebau wurde hier nicht nachgewiesen.

| Auslieferung | Bedeutung |
| --- | --- |
| Cloudflare | Veröffentlicht den Web- und Serverstand. Erzeugt keine Apple-Signatur und installiert keine native App. |
| Home-Screen-Web-App | Safari fügt die Website dem Home-Bildschirm hinzu; kein IPA-Paket und keine SideStore-Erneuerung. |
| Capacitor-IPA | Verpackt Web-Inhalte in einer nativen iOS-Hülle mit Adaptern. Braucht macOS-Bau, Geräte-IPA und Signierung. |

Übertragbar sind Download, Metadaten, Budgetsteuerung und SideStore-Anleitung. Die XcodeGen- und Kotlin/Rust-Bauschritte von BBT-Bit passen nicht zu Redions Capacitor-Projekt. Share-Erweiterung, Widgets, App Groups und lokale Dokumente brauchen eine eigene Prüfung. **Am Redion-Repository wurde nichts geändert.**
