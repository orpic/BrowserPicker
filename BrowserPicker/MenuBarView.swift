// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BrowserPicker")
                .font(.headline)

            Divider()

            Button("Settings...") {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }
            .keyboardShortcut(",")

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("BrowserPicker.openSettings")
    /// Posted with userInfo `["url": URL]` when the user wants the picker
    /// popup for a URL that didn't come through the system default-browser
    /// hand-off (e.g., from the History tab's "Open in..." action).
    static let routeURL = Notification.Name("BrowserPicker.routeURL")
}
