import Foundation

/// A dependency-free ZIP file with STORE entries. PNG files are already
/// compressed, so recompressing them would waste CPU and battery.
enum BBTScreenshotZIP {
    private struct CentralEntry {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    static func create(files: [URL], at destination: URL) throws {
        guard !files.isEmpty else { return }
        let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
        precondition(sortedFiles.count < Int(UInt16.max))
        var data = Data()
        var entries: [CentralEntry] = []
        for file in sortedFiles {
            let contents = try Data(contentsOf: file, options: .mappedIfSafe)
            guard contents.count <= Int(UInt32.max), data.count <= Int(UInt32.max) else {
                throw NSError(domain: "BBTScreenshotZIP", code: 1)
            }
            let name = Data(file.lastPathComponent.utf8)
            let size = UInt32(contents.count)
            let crc = checksum(contents)
            let offset = UInt32(data.count)

            data.append32(0x04034B50) // Local file header signature
            data.append16(20)         // ZIP 2.0
            data.append16(0)          // Flags
            data.append16(0)          // STORE (no compression)
            data.append16(0)          // Time
            data.append16(0)          // Date
            data.append32(crc)
            data.append32(size)
            data.append32(size)
            data.append16(UInt16(name.count))
            data.append16(0)
            data.append(name)
            data.append(contents)
            entries.append(CentralEntry(name: name, crc: crc, size: size, offset: offset))
        }

        let directoryOffset = UInt32(data.count)
        for entry in entries {
            data.append32(0x02014B50) // Central directory header
            data.append16(20)         // Creator version
            data.append16(20)         // Reader version
            data.append16(0)
            data.append16(0)
            data.append16(0)
            data.append16(0)
            data.append32(entry.crc)
            data.append32(entry.size)
            data.append32(entry.size)
            data.append16(UInt16(entry.name.count))
            data.append16(0)          // Extra length
            data.append16(0)          // Comment length
            data.append16(0)          // Disk number
            data.append16(0)          // Internal attributes
            data.append32(0)          // External attributes
            data.append32(entry.offset)
            data.append(entry.name)
        }
        let directorySize = UInt32(data.count) - directoryOffset
        data.append32(0x06054B50)
        data.append16(0)
        data.append16(0)
        data.append16(UInt16(entries.count))
        data.append16(UInt16(entries.count))
        data.append32(directorySize)
        data.append32(directoryOffset)
        data.append16(0)
        try data.write(to: destination, options: .atomic)
    }

    private static let crcTable: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) == 0 ? value >> 1 : (value >> 1) ^ 0xEDB88320
        }
        return value
    }

    private static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(byte)) & 0xFF)]
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private extension Data {
    mutating func append16(_ value: UInt16) {
        append(contentsOf: [UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8)])
    }
    mutating func append32(_ value: UInt32) {
        append(contentsOf: [
            UInt8(truncatingIfNeeded: value),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 24)
        ])
    }
}
