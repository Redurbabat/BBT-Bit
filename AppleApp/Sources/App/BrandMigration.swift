import Foundation

/// Einmalige Übernahme der unter dem alten Namen abgelegten Nutzerdaten.
///
/// Mit der Umbenennung von BitChord zu RED Bit änderten sich drei Dinge, die
/// ein Update sonst unsichtbar machen würde: die Ordnernamen auf der Platte,
/// zwei `UserDefaults`-Schlüssel der gesicherten Warteschlange und der
/// Gruppencontainer der Anmeldecookies. Die Übernahme läuft einmal beim Start
/// und bricht nie den Start ab: schlägt ein Schritt fehl, bleibt der alte
/// Bestand liegen und wird beim nächsten Start erneut versucht.
enum BrandMigration {
    private static let completedKey = "redbit_brand_migration_v2"
    private static let legacyDirectory = "BitChord"
    private static let currentDirectory = "RedBit"

    static func run(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: completedKey) else { return }
        migrateDirectories()
        discardLegacyCaches()
        discardLegacyTemporaryFiles()
        migrateDefaults(defaults)
        migrateCookies()
        defaults.set(true, forKey: completedKey)
    }

    // MARK: - Ordner

    /// Die Basisverzeichnisse, unter denen die App ihren eigenen Ordner führt.
    private static var bases: [URL] {
        let manager = FileManager.default
        var urls: [URL] = []
        for directory in [FileManager.SearchPathDirectory.documentDirectory,
                          .cachesDirectory,
                          .applicationSupportDirectory] {
            urls.append(contentsOf: manager.urls(for: directory, in: .userDomainMask))
        }
        if let group = manager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.babat.bbtbit") {
            urls.append(group)
        }
        return urls
    }

    /// Benennt `<Basis>/BitChord` in `<Basis>/RedBit` um. Liegt am Ziel schon
    /// etwas, bleibt der alte Ordner unangetastet — zusammenführen würde
    /// Downloads überschreiben, und das ist schlechter als ein Rest.
    private static func migrateDirectories() {
        let manager = FileManager.default
        for base in bases {
            let legacy = base.appendingPathComponent(legacyDirectory, isDirectory: true)
            let current = base.appendingPathComponent(currentDirectory, isDirectory: true)
            guard manager.fileExists(atPath: legacy.path),
                  !manager.fileExists(atPath: current.path) else { continue }
            do {
                try manager.moveItem(at: legacy, to: current)
            } catch {
                NSLog("[RED Bit] Ordnerübernahme fehlgeschlagen: %@", String(describing: error))
            }
        }
    }

    /// Blieb beim Umbenennen ein `Caches/BitChord` liegen, weil `Caches/RedBit`
    /// schon bestand, wird der alte Zweig verworfen. Caches sind wiederherstellbar;
    /// hier zu behalten kostet nur Platz.
    private static func discardLegacyCaches() {
        let manager = FileManager.default
        for base in manager.urls(for: .cachesDirectory, in: .userDomainMask) {
            let legacy = base.appendingPathComponent(legacyDirectory, isDirectory: true)
            let current = base.appendingPathComponent(currentDirectory, isDirectory: true)
            guard manager.fileExists(atPath: legacy.path),
                  manager.fileExists(atPath: current.path) else { continue }
            try? manager.removeItem(at: legacy)
        }
    }

    /// Angefangene Downloadstücke trugen den alten Namenspräfix. Nach der
    /// Umbenennung sucht niemand mehr danach, also räumt die Übernahme sie weg —
    /// auf einem gewachsenen Gerät sind das schnell ein paar hundert Megabyte.
    private static func discardLegacyTemporaryFiles() {
        let manager = FileManager.default
        let temporary = manager.temporaryDirectory
        let entries = (try? manager.contentsOfDirectory(
            at: temporary, includingPropertiesForKeys: nil)) ?? []
        for entry in entries where entry.lastPathComponent.hasPrefix("bitchord-") {
            try? manager.removeItem(at: entry)
        }
    }

    // MARK: - Gespeicherte Warteschlange

    private static let defaultsKeys = [
        ("bitchord_last_played", "redbit_last_played"),
        ("bitchord_last_played_previous", "redbit_last_played_previous"),
    ]

    /// Kopiert die alten Schlüssel, statt sie zu verschieben: ein Rückschritt
    /// auf eine ältere Fassung findet die Warteschlange dann noch vor.
    private static func migrateDefaults(_ defaults: UserDefaults) {
        for (legacy, current) in defaultsKeys {
            guard defaults.object(forKey: current) == nil,
                  let value = defaults.object(forKey: legacy) else { continue }
            defaults.set(value, forKey: current)
        }
    }

    // MARK: - Anmeldecookies

    /// Überträgt die Cookies aus dem früheren Gruppencontainer in den eigenen.
    /// Bereits vorhandene Cookies gleichen Namens bleiben stehen.
    private static func migrateCookies() {
        let legacy = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.app.bitchord.BitChord")
        let current = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.com.babat.bbtbit")
        guard let cookies = legacy.cookies, !cookies.isEmpty else { return }
        let existing = Set((current.cookies ?? []).map { "\($0.domain)\u{0}\($0.path)\u{0}\($0.name)" })
        for cookie in cookies {
            let identity = "\(cookie.domain)\u{0}\(cookie.path)\u{0}\(cookie.name)"
            guard !existing.contains(identity) else { continue }
            current.setCookie(cookie)
        }
    }
}
