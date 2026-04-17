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

    init(url: String, browserName: String, browserBundleID: String, profileName: String? = nil, incognito: Bool = false) {
        self.id = UUID()
        self.url = url
        self.browserName = browserName
        self.browserBundleID = browserBundleID
        self.profileName = profileName
        self.incognito = incognito
        self.timestamp = Date()
    }
}
