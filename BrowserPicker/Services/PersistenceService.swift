// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct PersistenceService {
    private static let appSupportDir: URL = {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BrowserPicker")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let fileURL = appSupportDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to filename: String) {
        let fileURL = appSupportDir.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else {
            print("[BrowserPicker] Failed to encode data for \(filename)")
            return
        }
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[BrowserPicker] Failed to write \(filename): \(error)")
        }
    }

    static func fileURL(for filename: String) -> URL {
        appSupportDir.appendingPathComponent(filename)
    }
}
