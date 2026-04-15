// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct BrowserProfile: Identifiable {
    let id: String
    let name: String
    let directoryName: String
    let email: String?
    let browserBundleID: String

    init(name: String, directoryName: String, email: String? = nil, browserBundleID: String) {
        self.id = "\(browserBundleID):\(directoryName)"
        self.name = name
        self.directoryName = directoryName
        self.email = email
        self.browserBundleID = browserBundleID
    }
}
