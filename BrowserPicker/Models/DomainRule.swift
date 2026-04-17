// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

enum RuleMatchType: String, Codable, CaseIterable {
    case domain
    case glob
    case regex
}

struct DomainRule: Codable, Identifiable {
    var id: UUID
    var pattern: String
    var matchType: RuleMatchType
    var browserBundleID: String
    var profileDirectory: String?
    var incognito: Bool
    var enabled: Bool
    var createdAt: Date

    init(
        pattern: String,
        matchType: RuleMatchType = .domain,
        browserBundleID: String,
        profileDirectory: String? = nil,
        incognito: Bool = false,
        enabled: Bool = true
    ) {
        self.id = UUID()
        self.pattern = pattern
        self.matchType = matchType
        self.browserBundleID = browserBundleID
        self.profileDirectory = profileDirectory
        self.incognito = incognito
        self.enabled = enabled
        self.createdAt = Date()
    }
}
