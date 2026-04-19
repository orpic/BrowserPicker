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

    static func match(url: URL, sourceAppBundleID: String? = nil) -> RuleMatch? {
        let rules = loadRules().filter(\.enabled)
        let urlString = url.absoluteString
        let host = url.host?.lowercased() ?? ""

        print("[BrowserPicker] Rule engine: checking \(rules.count) rule(s) against: \(urlString) (source: \(sourceAppBundleID ?? "unknown"))")

        for rule in rules {
            // Source app filter: if the rule specifies a source app, it must match.
            if let required = rule.sourceAppBundleID, !required.isEmpty {
                guard let actual = sourceAppBundleID, actual == required else { continue }
            }

            // URL pattern check. An empty pattern combined with a source app filter
            // means "match any URL from this app".
            let trimmedPattern = rule.pattern.trimmingCharacters(in: .whitespaces)
            let urlMatches: Bool
            if trimmedPattern.isEmpty {
                urlMatches = (rule.sourceAppBundleID?.isEmpty == false)
            } else {
                switch rule.matchType {
                case .domain:
                    urlMatches = matchesDomain(host: host, pattern: trimmedPattern.lowercased())
                case .glob:
                    urlMatches = matchesGlob(urlString: urlString, pattern: trimmedPattern)
                case .regex:
                    urlMatches = matchesRegex(urlString: urlString, pattern: trimmedPattern)
                }
            }

            if urlMatches {
                return RuleMatch(rule: rule, browserBundleID: rule.browserBundleID, profileDirectory: rule.profileDirectory, incognito: rule.incognito)
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
