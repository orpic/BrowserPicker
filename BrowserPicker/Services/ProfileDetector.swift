import Foundation

struct ProfileDetector {
    static func detectProfiles(for browser: Browser) -> [BrowserProfile] {
        switch browser.type {
        case .chromium:
            return detectChromiumProfiles(browser: browser)
        case .firefox:
            return detectFirefoxProfiles(browser: browser)
        case .safari, .unknown:
            return []
        }
    }

    // MARK: - Chromium

    private static func detectChromiumProfiles(browser: Browser) -> [BrowserProfile] {
        guard let appSupportDir = browser.appSupportDir else { return [] }

        let appSupport = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support")
            .appendingPathComponent(appSupportDir)
        let localStatePath = appSupport.appendingPathComponent("Local State")

        guard let data = try? Data(contentsOf: localStatePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: Any]
        else {
            return []
        }

        var profiles: [BrowserProfile] = []

        for (dirName, value) in infoCache {
            guard let profileDict = value as? [String: Any] else { continue }

            let name = profileDict["name"] as? String ?? dirName
            let email = profileDict["user_name"] as? String

            let profile = BrowserProfile(
                name: name,
                directoryName: dirName,
                email: email.flatMap { $0.isEmpty ? nil : $0 },
                browserBundleID: browser.bundleID
            )
            profiles.append(profile)
        }

        return profiles.sorted { $0.directoryName.localizedStandardCompare($1.directoryName) == .orderedAscending }
    }

    // MARK: - Firefox

    private static func detectFirefoxProfiles(browser: Browser) -> [BrowserProfile] {
        let profilesIniPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Firefox/profiles.ini")

        guard let contents = try? String(contentsOf: profilesIniPath, encoding: .utf8) else {
            return []
        }

        var profiles: [BrowserProfile] = []
        var currentName: String?
        var currentPath: String?
        var inProfileSection = false

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[Profile") {
                if let name = currentName, let path = currentPath {
                    profiles.append(BrowserProfile(
                        name: name,
                        directoryName: path,
                        browserBundleID: browser.bundleID
                    ))
                }
                currentName = nil
                currentPath = nil
                inProfileSection = true
                continue
            }

            if trimmed.hasPrefix("[") {
                if let name = currentName, let path = currentPath {
                    profiles.append(BrowserProfile(
                        name: name,
                        directoryName: path,
                        browserBundleID: browser.bundleID
                    ))
                }
                currentName = nil
                currentPath = nil
                inProfileSection = false
                continue
            }

            guard inProfileSection else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let val = parts[1].trimmingCharacters(in: .whitespaces)

            switch key {
            case "Name":
                currentName = val
            case "Path":
                currentPath = val
            default:
                break
            }
        }

        if inProfileSection, let name = currentName, let path = currentPath {
            profiles.append(BrowserProfile(
                name: name,
                directoryName: path,
                browserBundleID: browser.bundleID
            ))
        }

        return profiles
    }
}
