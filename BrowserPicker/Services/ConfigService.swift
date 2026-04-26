// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Foundation

struct ConfigPackage: Codable {
    static let currentSchemaVersion: Int = 1

    var schemaVersion: Int
    var exportedAt: Date
    var appVersion: String
    var rules: [DomainRule]
    var rewrites: [RewriteRule]
    var history: [HistoryEntry]?

    init(rules: [DomainRule], rewrites: [RewriteRule], history: [HistoryEntry]? = nil) {
        self.schemaVersion = Self.currentSchemaVersion
        self.exportedAt = Date()
        self.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        self.rules = rules
        self.rewrites = rewrites
        self.history = history
    }
}

enum ImportStrategy {
    /// Wipes existing rules and rewrites, then applies the imported config.
    case replace
    /// Appends imported rules and rewrites to existing ones, skipping
    /// any duplicates already present.
    case merge
}

struct ImportSummary {
    var rulesAdded: Int = 0
    var rulesSkipped: Int = 0
    var rewritesAdded: Int = 0
    var rewritesSkipped: Int = 0
    var historyImported: Int = 0
}

struct ConfigService {
    /// Builds a `ConfigPackage` from current persisted state.
    static func currentPackage(includeHistory: Bool) -> ConfigPackage {
        let rules = RuleEngine.loadRules()
        let rewrites = URLRewriter.loadRules()
        let history = includeHistory ? HistoryService.loadHistory() : nil
        return ConfigPackage(rules: rules, rewrites: rewrites, history: history)
    }

    /// Encodes a package as pretty-printed JSON suitable for writing to disk.
    static func encode(_ package: ConfigPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    /// Decodes a `ConfigPackage` from JSON data; supports the ISO8601 dates
    /// produced by `encode(_:)`.
    static func decode(_ data: Data) throws -> ConfigPackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ConfigPackage.self, from: data)
    }

    /// Applies an imported package using the chosen strategy and returns a
    /// summary the caller can show to the user.
    @discardableResult
    static func apply(_ package: ConfigPackage, strategy: ImportStrategy) -> ImportSummary {
        var summary = ImportSummary()

        switch strategy {
        case .replace:
            RuleEngine.saveRules(package.rules)
            URLRewriter.saveRules(package.rewrites)
            summary.rulesAdded = package.rules.count
            summary.rewritesAdded = package.rewrites.count

        case .merge:
            var existingRules = RuleEngine.loadRules()
            for incoming in package.rules {
                if existingRules.contains(where: { isDuplicate(existing: $0, incoming: incoming) }) {
                    summary.rulesSkipped += 1
                } else {
                    var copy = incoming
                    copy.id = UUID()
                    existingRules.append(copy)
                    summary.rulesAdded += 1
                }
            }
            RuleEngine.saveRules(existingRules)

            var existingRewrites = URLRewriter.loadRules()
            for incoming in package.rewrites {
                if existingRewrites.contains(where: { isDuplicate(existing: $0, incoming: incoming) }) {
                    summary.rewritesSkipped += 1
                } else {
                    var copy = incoming
                    copy.id = UUID()
                    existingRewrites.append(copy)
                    summary.rewritesAdded += 1
                }
            }
            URLRewriter.saveRules(existingRewrites)
        }

        // History is informational; we never overwrite history during
        // import. If the package contains history entries, we record the
        // count for display but do not persist them.
        summary.historyImported = package.history?.count ?? 0

        return summary
    }

    private static func isDuplicate(existing: DomainRule, incoming: DomainRule) -> Bool {
        existing.pattern.lowercased() == incoming.pattern.lowercased() &&
        existing.matchType == incoming.matchType &&
        existing.browserBundleID == incoming.browserBundleID &&
        (existing.profileDirectory ?? "") == (incoming.profileDirectory ?? "") &&
        (existing.sourceAppBundleID ?? "") == (incoming.sourceAppBundleID ?? "")
    }

    private static func isDuplicate(existing: RewriteRule, incoming: RewriteRule) -> Bool {
        existing.pattern == incoming.pattern && existing.replacement == incoming.replacement
    }
}
