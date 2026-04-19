// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(0)

            RulesSettingsTab()
                .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }
                .tag(1)

            RewriteSettingsTab()
                .tabItem { Label("Rewrite", systemImage: "arrow.triangle.swap") }
                .tag(2)

            HistorySettingsTab()
                .tabItem { Label("History", systemImage: "clock") }
                .tag(3)
        }
        .frame(width: 520, height: 420)
    }
}

private struct GeneralSettingsTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var isDefaultBrowser = false
    @State private var includeHistoryInExport = false
    @State private var pendingImport: ConfigPackage?
    @State private var importErrorMessage: String?
    @State private var importSummaryMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                aboutSection
                Divider()
                settingsSection
                Divider()
                defaultBrowserSection
                Divider()
                backupSection
            }
            .padding(20)
        }
        .onAppear { checkDefaultBrowser() }
        .sheet(item: Binding(
            get: { pendingImport.map { ImportSheetPayload(package: $0) } },
            set: { pendingImport = $0?.package }
        )) { payload in
            ImportPreviewSheet(package: payload.package, onApply: { strategy in
                let summary = ConfigService.apply(payload.package, strategy: strategy)
                importSummaryMessage = format(summary: summary, strategy: strategy)
                pendingImport = nil
            }, onCancel: {
                pendingImport = nil
            })
        }
        .alert("Import failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .alert("Import complete", isPresented: Binding(
            get: { importSummaryMessage != nil },
            set: { if !$0 { importSummaryMessage = nil } }
        )) {
            Button("OK") { importSummaryMessage = nil }
        } message: {
            Text(importSummaryMessage ?? "")
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .imageScale(.large)
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text("BrowserPicker")
                .font(.title2.bold())
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("GitHub", destination: URL(string: "https://github.com/orpic/BrowserPicker")!)
                .font(.caption)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("[BrowserPicker] Launch at login error: \(error)")
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
        }
    }

    private var defaultBrowserSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isDefaultBrowser ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(isDefaultBrowser ? .green : .orange)
                Text(isDefaultBrowser ? "BrowserPicker is your default browser" : "BrowserPicker is not the default browser")
                    .font(.callout)
            }

            if !isDefaultBrowser {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private func checkDefaultBrowser() {
        if let defaultBrowser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) {
            let bundleID = Bundle(url: defaultBrowser)?.bundleIdentifier
            isDefaultBrowser = bundleID == Bundle.main.bundleIdentifier
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Backup & Sharing")
                .font(.headline)

            Text("Export your rules and rewrites to a single file you can back up or share with teammates. Imported rules can replace yours or be merged in.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $includeHistoryInExport) {
                Text("Include link history in export")
                    .font(.caption)
            }
            .toggleStyle(.checkbox)
            .controlSize(.small)

            HStack {
                Button("Export…") {
                    runExport(includeHistory: includeHistoryInExport)
                }
                Button("Import…") {
                    runImport()
                }
                Spacer()
            }
        }
    }

    private func runExport(includeHistory: Bool) {
        let panel = NSSavePanel()
        panel.title = "Export BrowserPicker Configuration"
        panel.allowedContentTypes = [BrowserPickerConfigType.utType]
        panel.nameFieldStringValue = defaultExportFilename()
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        do {
            let package = ConfigService.currentPackage(includeHistory: includeHistory)
            let data = try ConfigService.encode(package)
            try data.write(to: destination, options: .atomic)
        } catch {
            importErrorMessage = "Could not write file: \(error.localizedDescription)"
        }
    }

    private func runImport() {
        let panel = NSOpenPanel()
        panel.title = "Import BrowserPicker Configuration"
        panel.allowedContentTypes = [BrowserPickerConfigType.utType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let source = panel.url else { return }

        do {
            let data = try Data(contentsOf: source)
            let package = try ConfigService.decode(data)
            pendingImport = package
        } catch {
            importErrorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func defaultExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "browserpicker-\(formatter.string(from: Date())).browserpicker"
    }

    private func format(summary: ImportSummary, strategy: ImportStrategy) -> String {
        var lines: [String] = []
        switch strategy {
        case .replace:
            lines.append("Replaced existing configuration.")
            lines.append("Rules imported: \(summary.rulesAdded)")
            lines.append("Rewrites imported: \(summary.rewritesAdded)")
        case .merge:
            lines.append("Merged into existing configuration.")
            lines.append("Rules added: \(summary.rulesAdded) (skipped \(summary.rulesSkipped) duplicates)")
            lines.append("Rewrites added: \(summary.rewritesAdded) (skipped \(summary.rewritesSkipped) duplicates)")
        }
        if summary.historyImported > 0 {
            lines.append("History entries in package: \(summary.historyImported) (not applied)")
        }
        return lines.joined(separator: "\n")
    }
}

enum BrowserPickerConfigType {
    static let utType: UTType = UTType(exportedAs: "com.orpic.browserpicker.config", conformingTo: .json)
}

private struct ImportSheetPayload: Identifiable {
    let id = UUID()
    let package: ConfigPackage
}

private struct ImportPreviewSheet: View {
    let package: ConfigPackage
    let onApply: (ImportStrategy) -> Void
    let onCancel: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import Configuration")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Label("\(package.rules.count) rule(s)", systemImage: "list.bullet.rectangle")
                Label("\(package.rewrites.count) rewrite(s)", systemImage: "arrow.triangle.swap")
                if let history = package.history, !history.isEmpty {
                    Label("\(history.count) history entries (will not be applied)", systemImage: "clock")
                        .foregroundStyle(.secondary)
                }
                Label("Exported \(Self.dateFormatter.string(from: package.exportedAt)) from v\(package.appVersion)", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Divider()

            Text("Choose how to apply this configuration:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Merge") { onApply(.merge) }
                    .help("Add imported rules to your existing ones, skipping duplicates")
                Button("Replace All") { onApply(.replace) }
                    .help("Wipe existing rules and rewrites, then apply the imported configuration")
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

private struct RulesSettingsTab: View {
    @State private var rules: [DomainRule] = []
    @State private var showingAddSheet = false
    @State private var editingRule: DomainRule?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("URL Rules")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if rules.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .imageScale(.large)
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No rules yet")
                        .foregroundStyle(.secondary)
                    Text("Rules let you automatically open specific domains\nin a chosen browser and profile.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Rules are matched top to bottom. First match wins. Drag to reorder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.08))

                List {
                    ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                        RuleRow(
                            priority: index + 1,
                            rule: rule,
                            onToggle: { toggleRule(rule) },
                            onEdit: { editingRule = rule },
                            onDelete: { deleteRule(rule) }
                        )
                    }
                    .onMove(perform: moveRule)
                }
            }

            Divider()

            RuleTesterSection(rules: rules)
        }
        .onAppear { rules = RuleEngine.loadRules() }
        .sheet(isPresented: $showingAddSheet) {
            RuleEditorSheet(editingRule: nil, onSave: { rule in
                rules.append(rule)
                RuleEngine.saveRules(rules)
            })
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorSheet(editingRule: rule, onSave: { updated in
                if let index = rules.firstIndex(where: { $0.id == updated.id }) {
                    rules[index] = updated
                    RuleEngine.saveRules(rules)
                }
            })
        }
    }

    private func toggleRule(_ rule: DomainRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].enabled.toggle()
            RuleEngine.saveRules(rules)
        }
    }

    private func deleteRule(_ rule: DomainRule) {
        rules.removeAll { $0.id == rule.id }
        RuleEngine.saveRules(rules)
    }

    private func moveRule(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        RuleEngine.saveRules(rules)
    }
}

private struct RuleTesterSection: View {
    let rules: [DomainRule]
    @State private var input: String = ""
    @State private var simulatedSourceAppID: String = ""
    @State private var sourceApps: [RunningAppOption] = []
    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://example.com/path", text: $input)
                    .textFieldStyle(.roundedBorder)

                Picker("Simulate source app", selection: $simulatedSourceAppID) {
                    Text("None").tag("")
                    ForEach(sourceApps) { app in
                        Text(app.name).tag(app.bundleID)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                if !input.isEmpty {
                    resultView
                }
            }
            .padding(.top, 6)
        } label: {
            Label("Test a URL", systemImage: "wand.and.stars")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear { sourceApps = detectRunningSourceApps() }
    }

    @ViewBuilder
    private var resultView: some View {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            let trace = URLRewriter.traceRewrite(trimmed)
            let finalURL = URL(string: trace.finalURL) ?? url
            let sourceApp: String? = simulatedSourceAppID.isEmpty ? nil : simulatedSourceAppID
            let match = RuleEngine.match(url: finalURL, sourceAppBundleID: sourceApp)

            VStack(alignment: .leading, spacing: 6) {
                if !trace.steps.isEmpty {
                    rewriteChainView(steps: trace.steps)
                }

                matchView(finalURL: finalURL, match: match)
            }
        } else {
            Text("Enter a valid URL (including http:// or https://)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private func rewriteChainView(steps: [RewriteStep]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rewrites applied")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                VStack(alignment: .leading, spacing: 1) {
                    Text("/\(step.rule.pattern)/")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Text(step.after)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    @ViewBuilder
    private func matchView(finalURL: URL, match: RuleMatch?) -> some View {
        if let match = match {
            let priority = (rules.firstIndex(where: { $0.id == match.rule.id }) ?? -1) + 1
            let browserName = browserDisplayName(for: match.browserBundleID)
            let profileName = profileDisplayName(bundleID: match.browserBundleID, directory: match.profileDirectory)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Matches rule #\(priority)")
                    .font(.caption.bold())
                Text("→ \(browserName)\(profileName.map { " / \($0)" } ?? "")\(match.incognito ? " (incognito)" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("No rule matches — popup would be shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func browserDisplayName(for bundleID: String) -> String {
        if let browser = BrowserDetector.detectInstalledBrowsers().first(where: { $0.bundleID == bundleID }) {
            return browser.name
        }
        return bundleID.components(separatedBy: ".").last ?? bundleID
    }

    private func profileDisplayName(bundleID: String, directory: String?) -> String? {
        guard let directory = directory else { return nil }
        guard let browser = BrowserDetector.detectInstalledBrowsers().first(where: { $0.bundleID == bundleID }) else {
            return directory
        }
        let profiles = ProfileDetector.detectProfiles(for: browser)
        return profiles.first(where: { $0.directoryName == directory })?.name ?? directory
    }
}

private struct RuleRow: View {
    let priority: Int
    let rule: DomainRule
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("#\(priority)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(minWidth: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if rule.pattern.isEmpty {
                        Text("(any URL)")
                            .font(.system(.callout, design: .monospaced, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(rule.pattern)
                            .font(.system(.callout, design: .monospaced, weight: .medium))
                        Text("(\(rule.matchType.rawValue))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                HStack(spacing: 4) {
                    if let appID = rule.sourceAppBundleID, !appID.isEmpty {
                        Image(systemName: "app.dashed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("from \(appID.components(separatedBy: ".").last ?? appID)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(rule.browserBundleID.components(separatedBy: ".").last ?? rule.browserBundleID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let profile = rule.profileDirectory {
                        Text("→ \(profile)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if rule.incognito {
                        Image(systemName: "eye.slash")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(get: { rule.enabled }, set: { _ in onToggle() }))
                .toggleStyle(.switch)
                .controlSize(.small)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit rule")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete rule")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onEdit)
    }
}

private struct RunningAppOption: Identifiable, Hashable {
    let id: String
    let name: String
    var bundleID: String { id }
}

private func detectRunningSourceApps() -> [RunningAppOption] {
    var seen = Set<String>()
    let apps: [RunningAppOption] = NSWorkspace.shared.runningApplications.compactMap { app in
        guard let bundleID = app.bundleIdentifier, app.activationPolicy != .prohibited else { return nil }
        if seen.contains(bundleID) { return nil }
        seen.insert(bundleID)
        let name = app.localizedName ?? bundleID
        return RunningAppOption(id: bundleID, name: name)
    }
    return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

private struct RuleEditorSheet: View {
    let editingRule: DomainRule?
    let onSave: (DomainRule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var matchType: RuleMatchType = .domain
    @State private var selectedBrowserID = ""
    @State private var selectedProfileDir = ""
    @State private var incognito = false
    @State private var selectedSourceAppID = ""
    @State private var browsers: [Browser] = []
    @State private var profiles: [BrowserProfile] = []
    @State private var sourceApps: [RunningAppOption] = []

    private var isEditing: Bool { editingRule != nil }
    private var hasSourceApp: Bool { !selectedSourceAppID.isEmpty }
    private var canSave: Bool {
        guard !selectedBrowserID.isEmpty else { return false }
        // Must have at least a pattern or a source app filter.
        return !pattern.trimmingCharacters(in: .whitespaces).isEmpty || hasSourceApp
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Rule" : "Add Rule")
                .font(.headline)

            Form {
                TextField("Pattern", text: $pattern, prompt: Text(hasSourceApp ? "Optional when source app is set" : "e.g. github.com"))
                Picker("Match type", selection: $matchType) {
                    ForEach(RuleMatchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Source app", selection: $selectedSourceAppID) {
                    Text("Any").tag("")
                    if let editing = editingRule,
                       let bundleID = editing.sourceAppBundleID,
                       !bundleID.isEmpty,
                       !sourceApps.contains(where: { $0.bundleID == bundleID }) {
                        Text("\(bundleID) (not running)").tag(bundleID)
                    }
                    ForEach(sourceApps) { app in
                        Text(app.name).tag(app.bundleID)
                    }
                }
                Picker("Browser", selection: $selectedBrowserID) {
                    Text("Select...").tag("")
                    ForEach(browsers) { browser in
                        Text(browser.name).tag(browser.bundleID)
                    }
                }
                .onChange(of: selectedBrowserID) { _, newValue in
                    if let browser = browsers.first(where: { $0.bundleID == newValue }) {
                        profiles = ProfileDetector.detectProfiles(for: browser)
                    } else {
                        profiles = []
                    }
                    if !profiles.contains(where: { $0.directoryName == selectedProfileDir }) {
                        selectedProfileDir = ""
                    }
                }
                if !profiles.isEmpty {
                    Picker("Profile", selection: $selectedProfileDir) {
                        Text("Default").tag("")
                        ForEach(profiles) { profile in
                            Text(profile.name).tag(profile.directoryName)
                        }
                    }
                }
                Toggle("Incognito / Private", isOn: $incognito)
            }

            if hasSourceApp {
                Text("Only links coming from this app will match this rule.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let cleanPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
                    let sourceApp = selectedSourceAppID.isEmpty ? nil : selectedSourceAppID
                    var rule = editingRule ?? DomainRule(
                        pattern: cleanPattern,
                        matchType: matchType,
                        browserBundleID: selectedBrowserID,
                        profileDirectory: selectedProfileDir.isEmpty ? nil : selectedProfileDir,
                        incognito: incognito,
                        sourceAppBundleID: sourceApp
                    )
                    if isEditing {
                        rule.pattern = cleanPattern
                        rule.matchType = matchType
                        rule.browserBundleID = selectedBrowserID
                        rule.profileDirectory = selectedProfileDir.isEmpty ? nil : selectedProfileDir
                        rule.incognito = incognito
                        rule.sourceAppBundleID = sourceApp
                    }
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            browsers = BrowserDetector.detectInstalledBrowsers()
            sourceApps = detectRunningSourceApps()
            if let rule = editingRule {
                pattern = rule.pattern
                matchType = rule.matchType
                selectedBrowserID = rule.browserBundleID
                selectedProfileDir = rule.profileDirectory ?? ""
                incognito = rule.incognito
                selectedSourceAppID = rule.sourceAppBundleID ?? ""
                if let browser = browsers.first(where: { $0.bundleID == rule.browserBundleID }) {
                    profiles = ProfileDetector.detectProfiles(for: browser)
                }
            }
        }
    }
}

private struct RewriteSettingsTab: View {
    @State private var rules: [RewriteRule] = []
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("URL Rewrite Rules")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if rules.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.swap")
                        .imageScale(.large)
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No rewrite rules yet")
                        .foregroundStyle(.secondary)
                    Text("Rewrite rules transform URLs before routing.\nE.g. strip tracking parameters or force HTTPS.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                List {
                    ForEach(rules) { rule in
                        RewriteRuleRow(rule: rule, onToggle: { toggleRule(rule) }, onDelete: { deleteRule(rule) })
                    }
                }
            }
        }
        .onAppear { rules = URLRewriter.loadRules() }
        .sheet(isPresented: $showingAddSheet) {
            AddRewriteRuleSheet(onSave: { rule in
                rules.append(rule)
                URLRewriter.saveRules(rules)
            })
        }
    }

    private func toggleRule(_ rule: RewriteRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].enabled.toggle()
            URLRewriter.saveRules(rules)
        }
    }

    private func deleteRule(_ rule: RewriteRule) {
        rules.removeAll { $0.id == rule.id }
        URLRewriter.saveRules(rules)
    }
}

private struct RewriteRuleRow: View {
    let rule: RewriteRule
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.pattern)
                    .font(.system(.callout, design: .monospaced))
                Text("→ \(rule.replacement)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(get: { rule.enabled }, set: { _ in onToggle() }))
                .toggleStyle(.switch)
                .controlSize(.small)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct AddRewriteRuleSheet: View {
    let onSave: (RewriteRule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var replacement = ""
    @State private var sampleURL = ""

    private var regexError: String? {
        guard !pattern.isEmpty else { return nil }
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var previewOutput: String? {
        guard !sampleURL.isEmpty, !pattern.isEmpty, regexError == nil else { return nil }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(sampleURL.startIndex..., in: sampleURL)
        return regex.stringByReplacingMatches(in: sampleURL, range: range, withTemplate: replacement)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Rewrite Rule")
                .font(.headline)

            Form {
                TextField("Pattern (regex)", text: $pattern, prompt: Text("e.g. (.+)\\?utm_.*"))
                TextField("Replacement", text: $replacement, prompt: Text("e.g. $1"))
            }

            if let error = regexError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
            }

            Text("Uses regex with capture groups. $1, $2, etc. reference matched groups.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Try it on a URL")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                TextField("https://example.com/?utm_source=x", text: $sampleURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))

                if let output = previewOutput {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(output)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(output == sampleURL ? .tertiary : .primary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    if output == sampleURL && !sampleURL.isEmpty {
                        Text("Pattern did not match this URL")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let rule = RewriteRule(pattern: pattern, replacement: replacement)
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty || regexError != nil)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

private struct HistorySettingsTab: View {
    @State private var entries: [HistoryEntry] = []
    @State private var searchText = ""
    @State private var exportError: String?

    private var filteredEntries: [HistoryEntry] {
        if searchText.isEmpty { return entries }
        let query = searchText.lowercased()
        return entries.filter {
            $0.url.lowercased().contains(query) ||
            $0.browserName.lowercased().contains(query) ||
            ($0.profileName?.lowercased().contains(query) ?? false)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Link History")
                    .font(.headline)
                Spacer()
                Text("\(entries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Export…") { exportCSV() }
                    .controlSize(.small)
                    .disabled(entries.isEmpty)
                Button("Clear") {
                    HistoryService.clearHistory()
                    entries = []
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            Divider()

            if filteredEntries.isEmpty {
                Spacer()
                Text(searchText.isEmpty ? "No history yet" : "No matches")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(filteredEntries) { entry in
                    HistoryRow(entry: entry, onReopen: { reopen(entry) }, onOpenIn: { openInPicker(entry) })
                }
            }
        }
        .onAppear { entries = HistoryService.loadHistory() }
        .alert("Export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private func reopen(_ entry: HistoryEntry) {
        guard let url = URL(string: entry.url) else { return }
        let browsers = BrowserDetector.detectInstalledBrowsers()
        guard let browser = browsers.first(where: { $0.bundleID == entry.browserBundleID }) else {
            // Browser is no longer installed — fall back to the picker.
            openInPicker(entry)
            return
        }
        let profile: BrowserProfile? = {
            guard let profileName = entry.profileName else { return nil }
            return ProfileDetector.detectProfiles(for: browser).first { $0.name == profileName }
        }()
        URLLauncher.launch(url: url, browser: browser, profile: profile, incognito: entry.incognito)
        HistoryService.log(url: url, browser: browser, profile: profile, incognito: entry.incognito)
        entries = HistoryService.loadHistory()
    }

    private func openInPicker(_ entry: HistoryEntry) {
        guard let url = URL(string: entry.url) else { return }
        NotificationCenter.default.post(name: .routeURL, object: nil, userInfo: ["url": url])
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "Export Link History"
        panel.allowedContentTypes = [.commaSeparatedText]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "browserpicker-history-\(formatter.string(from: Date())).csv"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        do {
            let csv = HistoryCSV.build(from: entries)
            try csv.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            exportError = "Could not write file: \(error.localizedDescription)"
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let onReopen: () -> Void
    let onOpenIn: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.url)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            HStack(spacing: 4) {
                Text(entry.browserName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let profile = entry.profileName {
                    Text("→ \(profile)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if entry.incognito {
                    Image(systemName: "eye.slash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Self.dateFormatter.string(from: entry.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onReopen) {
                Label("Re-open in \(entry.browserName)", systemImage: "arrow.clockwise")
            }
            Button(action: onOpenIn) {
                Label("Open in…", systemImage: "questionmark.app")
            }
            Divider()
            Button(action: copyURL) {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
        }
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.url, forType: .string)
    }
}

enum HistoryCSV {
    static func build(from entries: [HistoryEntry]) -> String {
        let header = "timestamp,url,browser,profile,incognito"
        let isoFormatter = ISO8601DateFormatter()
        let rows = entries.map { entry -> String in
            let fields = [
                isoFormatter.string(from: entry.timestamp),
                entry.url,
                entry.browserName,
                entry.profileName ?? "",
                entry.incognito ? "true" : "false",
            ]
            return fields.map(escape).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        if !needsQuoting { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
