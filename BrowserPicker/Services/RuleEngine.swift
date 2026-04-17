// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct RuleMatch {
    let rule: DomainRule
    let browserBundleID: String
    let profileDirectory: String?
    let incognito: Bool
}

struct RuleEngine {
    private static let rulesFile = "rules.json"

    static func loadRules() -> [DomainRule] {
        PersistenceService.load([DomainRule].self, from: rulesFile) ?? []
    }

    static func saveRules(_ rules: [DomainRule]) {
        PersistenceService.save(rules, to: rulesFile)
    }

    static func match(url: URL) -> RuleMatch? {
        let rules = loadRules().filter(\.enabled)
        let urlString = url.absoluteString
        let host = url.host?.lowercased() ?? ""

        print("[BrowserPicker] Rule engine: checking \(rules.count) rule(s) against: \(urlString)")

        for rule in rules {
            switch rule.matchType {
            case .domain:
                if matchesDomain(host: host, pattern: rule.pattern.lowercased()) {
                    return RuleMatch(rule: rule, browserBundleID: rule.browserBundleID, profileDirectory: rule.profileDirectory, incognito: rule.incognito)
                }
            case .glob:
                if matchesGlob(urlString: urlString, pattern: rule.pattern) {
                    return RuleMatch(rule: rule, browserBundleID: rule.browserBundleID, profileDirectory: rule.profileDirectory, incognito: rule.incognito)
                }
            case .regex:
                if matchesRegex(urlString: urlString, pattern: rule.pattern) {
                    return RuleMatch(rule: rule, browserBundleID: rule.browserBundleID, profileDirectory: rule.profileDirectory, incognito: rule.incognito)
                }
            }
        }

        return nil
    }

    private static func matchesDomain(host: String, pattern: String) -> Bool {
        if host == pattern { return true }
        if host.hasSuffix(".\(pattern)") { return true }
        return false
    }

    private static func matchesGlob(urlString: String, pattern: String) -> Bool {
        let regexPattern = "^" + NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".") + "$"

        return matchesRegex(urlString: urlString, pattern: regexPattern)
    }

    private static func matchesRegex(urlString: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(urlString.startIndex..., in: urlString)
        return regex.firstMatch(in: urlString, range: range) != nil
    }
}
