import Foundation
import Observation

enum AppTestSessionState: String, Codable {
    case running, completed, interrupted
}

struct AppTestSessionSummary: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let updatedAt: Date
    let finishedAt: Date?
    let state: AppTestSessionState
    let sampleCount: Int
    let manualPassed: Int
    let manualFailed: Int
    let manualTotal: Int
}

enum AppTestReportError: LocalizedError {
    case noSession, invalidReport
    var errorDescription: String? {
        switch self {
        case .noSession: "Starte zuerst einen App-Test."
        case .invalidReport: "Dieser Testbericht konnte nicht gelesen werden. Die Datei bleibt erhalten."
        }
    }
}

/// Ein Bericht je Sitzung; Zwischenstände ersetzen nur dieselbe UUID atomar.
@MainActor @Observable final class AppTestReportStore {
    static let shared = AppTestReportStore()
    private(set) var reports: [AppTestSessionSummary] = []
    private(set) var unreadableCount = 0
    private let directory: URL
    private struct Header: Decodable {
        let version: Int
        let summary: AppTestSessionSummary
    }

    init(directory: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.directory = directory ?? support.appendingPathComponent("RED-Bit/Testberichte", isDirectory: true)
        refresh(recoverInterrupted: true)
    }

    func save(_ data: Data) throws -> URL {
        let summary = try decode(data)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = fileURL(summary.id)
        try data.write(to: url, options: .atomic)
        reports.removeAll { $0.id == summary.id }
        reports.append(summary); reports.sort { $0.updatedAt > $1.updatedAt }
        return url
    }

    func read(_ id: UUID) throws -> Data {
        let url = fileURL(id)
        guard try (url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 8 * 1024 * 1024 else {
            throw AppTestReportError.invalidReport
        }
        let data = try Data(contentsOf: url)
        guard try decode(data).id == id else { throw AppTestReportError.invalidReport }
        return data
    }

    func fileURL(_ id: UUID) -> URL { directory.appendingPathComponent("\(id.uuidString.lowercased()).json") }

    func refresh(recoverInterrupted: Bool = false) {
        reports = []; unreadableCount = 0
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            for url in urls where url.pathExtension == "json" {
                do {
                    guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else {
                        unreadableCount += 1; continue
                    }
                    var data = try read(id)
                    var summary = try decode(data)
                    if recoverInterrupted, summary.state == .running {
                        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              var header = object["summary"] as? [String: Any] else {
                            throw AppTestReportError.invalidReport
                        }
                        header["state"] = AppTestSessionState.interrupted.rawValue
                        object["summary"] = header
                        data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
                        try data.write(to: url, options: .atomic)
                        summary = try decode(data)
                    }
                    reports.append(summary)
                } catch { unreadableCount += 1 }
            }
            reports.sort { $0.updatedAt > $1.updatedAt }
        } catch { unreadableCount += 1 }
    }

    private func decode(_ data: Data) throws -> AppTestSessionSummary {
        guard data.count <= 8 * 1024 * 1024 else { throw AppTestReportError.invalidReport }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let header = try decoder.decode(Header.self, from: data)
        let s = header.summary
        guard header.version == 4, (0...1800).contains(s.sampleCount), s.manualTotal >= 0,
              s.manualPassed >= 0, s.manualFailed >= 0, s.manualPassed <= s.manualTotal,
              s.manualFailed <= s.manualTotal - s.manualPassed else {
            throw AppTestReportError.invalidReport
        }
        return s
    }
}
