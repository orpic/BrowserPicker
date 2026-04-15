import AppKit

enum BrowserType: String {
    case chromium
    case firefox
    case safari
    case unknown
}

struct BrowserInfo {
    let bundleID: String
    let type: BrowserType
    let appSupportDir: String?
}

struct Browser: Identifiable {
    let id: String
    let name: String
    let bundleID: String
    let path: URL
    let icon: NSImage
    let type: BrowserType
    let appSupportDir: String?

    static let knownBrowsers: [String: BrowserInfo] = [
        "com.apple.Safari": BrowserInfo(
            bundleID: "com.apple.Safari",
            type: .safari,
            appSupportDir: nil
        ),
        "com.google.Chrome": BrowserInfo(
            bundleID: "com.google.Chrome",
            type: .chromium,
            appSupportDir: "Google/Chrome"
        ),
        "com.google.Chrome.beta": BrowserInfo(
            bundleID: "com.google.Chrome.beta",
            type: .chromium,
            appSupportDir: "Google/Chrome Beta"
        ),
        "com.google.Chrome.dev": BrowserInfo(
            bundleID: "com.google.Chrome.dev",
            type: .chromium,
            appSupportDir: "Google/Chrome Dev"
        ),
        "org.mozilla.firefox": BrowserInfo(
            bundleID: "org.mozilla.firefox",
            type: .firefox,
            appSupportDir: "Firefox"
        ),
        "com.microsoft.edgemac": BrowserInfo(
            bundleID: "com.microsoft.edgemac",
            type: .chromium,
            appSupportDir: "Microsoft Edge"
        ),
        "com.brave.Browser": BrowserInfo(
            bundleID: "com.brave.Browser",
            type: .chromium,
            appSupportDir: "BraveSoftware/Brave-Browser"
        ),
        "company.thebrowser.Browser": BrowserInfo(
            bundleID: "company.thebrowser.Browser",
            type: .chromium,
            appSupportDir: "Arc"
        ),
        "com.vivaldi.Vivaldi": BrowserInfo(
            bundleID: "com.vivaldi.Vivaldi",
            type: .chromium,
            appSupportDir: "Vivaldi"
        ),
        "com.operasoftware.Opera": BrowserInfo(
            bundleID: "com.operasoftware.Opera",
            type: .chromium,
            appSupportDir: "com.operasoftware.Opera"
        ),
    ]
}
