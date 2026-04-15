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
