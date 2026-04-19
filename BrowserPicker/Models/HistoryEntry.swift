// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct HistoryEntry: Codable, Identifiable {
    var id: UUID
    var url: String
    var browserName: String
    var browserBundleID: String
    var profileName: String?
    var incognito: Bool
    var timestamp: Date
    /// True if this open was decided automatically by a matching rule.
    /// False if the user picked the browser/profile from the popup (or
    /// re-opened the link from history). Optional for backward compatibility
    /// with history.json files written before this field existed.
    var viaRule: Bool?

    init(
        url: String,
        browserName: String,
        browserBundleID: String,
        profileName: String? = nil,
        incognito: Bool = false,
        viaRule: Bool = false
    ) {
        self.id = UUID()
        self.url = url
        self.browserName = browserName
        self.browserBundleID = browserBundleID
        self.profileName = profileName
        self.incognito = incognito
        self.timestamp = Date()
        self.viaRule = viaRule
    }
}
