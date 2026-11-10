import SwiftUI

extension SettingsView {
    func buildTestRows(_ rows: inout SettingsRows) {
        appendTestCenterRow(&rows)
        rows.row("Gespeicherte Testberichte", "JSON", "Dateien", "speichern", "teilen", "Verlauf", "Ergebnis") {
            PushLink { AppTestReportsView() } label: {
                SettingsLine(glyph: .nerd, title: "Gespeicherte Testberichte",
                    subtitle: "Abgeschlossene Tests und letzte Speicherstände öffnen") { EmptyView() }
            }
            .accessibilityIdentifier("red.tests.savedReports")
        }
        rows.row("Diagnostic Reports", "Diagnose", "Audio", "Stream", "Fehler") {
            PushLink { DiagnosticReportsView() } label: {
                SettingsLine(glyph: .nerd, title: "Diagnostic Reports",
                    subtitle: "Musik- und Streamdiagnose ansehen") { EmptyView() }
            }
        }
        #if os(iOS)
        rows.row("15 Liquid-Motion-Designs automatisch prüfen", "Design", "Vorschau", "Selbsttest") {
            PushLink { LiquidMotionDeviceSelfTestView() } label: {
                SettingsLine(glyph: .automix, title: "15 Liquid-Motion-Designs automatisch prüfen",
                    subtitle: "Separate Designprüfung mit gekennzeichneten Beispieldaten") { EmptyView() }
            }
        }
        #endif
    }
}
