// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct HistoryService {
    private static let historyFile = "history.json"
    private static let maxEntries = 500

    static func log(url: URL, browser: Browser, profile: BrowserProfile?, incognito: Bool) {
        var entries = loadHistory()

        let entry = HistoryEntry(
            url: url.absoluteString,
            browserName: browser.name,
            browserBundleID: browser.bundleID,
            profileName: profile?.name,
            incognito: incognito
        )

        entries.insert(entry, at: 0)

        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        PersistenceService.save(entries, to: historyFile)
    }

    static func loadHistory() -> [HistoryEntry] {
        PersistenceService.load([HistoryEntry].self, from: historyFile) ?? []
    }

    static func clearHistory() {
        PersistenceService.save([HistoryEntry](), to: historyFile)
    }
}
