// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit

struct BrowserDetector {
    static func detectInstalledBrowsers() -> [Browser] {
        guard let httpURL = URL(string: "https://example.com") else { return [] }

        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: httpURL)
        var browsers: [Browser] = []

        for appURL in appURLs {
            guard let bundle = Bundle(url: appURL),
                  let bundleID = bundle.bundleIdentifier,
                  let info = Browser.knownBrowsers[bundleID]
            else {
                continue
            }

            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 32, height: 32)

            let browser = Browser(
                id: bundleID,
                name: name,
                bundleID: bundleID,
                path: appURL,
                icon: icon,
                type: info.type,
                appSupportDir: info.appSupportDir
            )
            browsers.append(browser)
        }

        return browsers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
