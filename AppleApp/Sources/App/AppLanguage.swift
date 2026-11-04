import Foundation

enum AppLanguage {
    static let preferenceKey = "app_language"
    static let defaultIdentifier = "de"

    static func identifier(in defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: preferenceKey) ?? defaultIdentifier
    }

    static func locale(for identifier: String) -> Locale {
        identifier.isEmpty ? .autoupdatingCurrent : Locale(identifier: identifier)
    }

    /// Meldungen außerhalb von SwiftUI verwenden dieselbe Sprache wie die Ansichten.
    static func localized(_ key: String, bundle: Bundle = .main, defaults: UserDefaults = .standard) -> String {
        let language = identifier(in: defaults)
        if !language.isEmpty,
           let preferred = Bundle.preferredLocalizations(from: bundle.localizations, forPreferences: [language]).first,
           let path = bundle.path(forResource: preferred, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle.localizedString(forKey: key, value: key, table: nil)
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
