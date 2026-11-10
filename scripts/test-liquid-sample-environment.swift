import SwiftUI

/// Typprüfung gegen die echte gemeinsame Definition, ohne iOS-Aufnahmedienst
/// oder native Audio-Frameworks. Ein iOS-exklusiver Schlüssel muss hier scheitern.
struct LiquidSampleEnvironmentCompileCheck: View {
    @Environment(\.liquidDesignSample) private var sample

    var body: some View {
        Text(sample ? "Beispieldaten" : "Echte Daten")
            .environment(\.liquidDesignSample, true)
    }
}
