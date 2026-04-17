// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct RewriteRule: Codable, Identifiable {
    var id: UUID
    var pattern: String
    var replacement: String
    var enabled: Bool
    var createdAt: Date

    init(pattern: String, replacement: String, enabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.replacement = replacement
        self.enabled = enabled
        self.createdAt = Date()
    }
}
