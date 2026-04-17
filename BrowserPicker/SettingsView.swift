// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI
import ServiceManagement

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

    var body: some View {
        VStack(spacing: 16) {
            aboutSection
            Divider()
            settingsSection
            Divider()
            defaultBrowserSection
            Spacer()
        }
        .padding(20)
        .onAppear { checkDefaultBrowser() }
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
}

private struct RulesSettingsTab: View {
    @State private var rules: [DomainRule] = []
    @State private var showingAddSheet = false

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
                List {
                    ForEach(rules) { rule in
                        RuleRow(rule: rule, onToggle: { toggleRule(rule) }, onDelete: { deleteRule(rule) })
                    }
                }
            }
        }
        .onAppear { rules = RuleEngine.loadRules() }
        .sheet(isPresented: $showingAddSheet) {
            AddRuleSheet(onSave: { rule in
                rules.append(rule)
                RuleEngine.saveRules(rules)
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
}

private struct RuleRow: View {
    let rule: DomainRule
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(rule.pattern)
                        .font(.system(.callout, design: .monospaced, weight: .medium))
                    Text("(\(rule.matchType.rawValue))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 4) {
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

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct AddRuleSheet: View {
    let onSave: (DomainRule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var matchType: RuleMatchType = .domain
    @State private var selectedBrowserID = ""
    @State private var selectedProfileDir = ""
    @State private var incognito = false
    @State private var browsers: [Browser] = []
    @State private var profiles: [BrowserProfile] = []

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Rule")
                .font(.headline)

            Form {
                TextField("Pattern", text: $pattern, prompt: Text("e.g. github.com"))
                Picker("Match type", selection: $matchType) {
                    ForEach(RuleMatchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
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
                    selectedProfileDir = ""
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

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let cleanPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
                    let rule = DomainRule(
                        pattern: cleanPattern,
                        matchType: matchType,
                        browserBundleID: selectedBrowserID,
                        profileDirectory: selectedProfileDir.isEmpty ? nil : selectedProfileDir,
                        incognito: incognito
                    )
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty || selectedBrowserID.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear {
            browsers = BrowserDetector.detectInstalledBrowsers()
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

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Rewrite Rule")
                .font(.headline)

            Form {
                TextField("Pattern (regex)", text: $pattern, prompt: Text("e.g. (.+)\\?utm_.*"))
                TextField("Replacement", text: $replacement, prompt: Text("e.g. $1"))
            }

            Text("Uses regex with capture groups. $1, $2, etc. reference matched groups.")
                .font(.caption)
                .foregroundStyle(.tertiary)

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
                .disabled(pattern.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}

private struct HistorySettingsTab: View {
    @State private var entries: [HistoryEntry] = []
    @State private var searchText = ""

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
                }
            }
        }
        .onAppear { entries = HistoryService.loadHistory() }
    }
}
