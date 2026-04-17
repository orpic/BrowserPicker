// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct URLRewriter {
    private static let rulesFile = "rewrite-rules.json"

    static func loadRules() -> [RewriteRule] {
        PersistenceService.load([RewriteRule].self, from: rulesFile) ?? []
    }

    static func saveRules(_ rules: [RewriteRule]) {
        PersistenceService.save(rules, to: rulesFile)
    }

    static func rewrite(_ url: URL) -> URL {
        let rules = loadRules().filter(\.enabled)
        var urlString = url.absoluteString

        for rule in rules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(urlString.startIndex..., in: urlString)
            let result = regex.stringByReplacingMatches(in: urlString, range: range, withTemplate: rule.replacement)
            if result != urlString {
                urlString = result
                print("[BrowserPicker] URL rewritten by rule '\(rule.pattern)': \(url.absoluteString) → \(urlString)")
            }
        }

        return URL(string: urlString) ?? url
    }
}
