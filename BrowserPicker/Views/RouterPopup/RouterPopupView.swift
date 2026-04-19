// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

enum RememberTarget: String, CaseIterable, Identifiable {
    case domain
    case sourceApp
    var id: String { rawValue }
}

struct RouterPopupView: View {
    let url: URL
    let browsers: [Browser]
    let profiles: [String: [BrowserProfile]]
    let sourceAppBundleID: String?
    let sourceAppName: String?
    @ObservedObject var keyboardState: PopupKeyboardState
    let onProfileSelected: (Browser, BrowserProfile?, Bool) -> Void

    @State private var selectedBrowserID: String?
    @State private var highlightedIndex: Int = 0
    @State private var highlightedProfileIndex: Int = -1
    @State private var isInProfilePanel: Bool = false
    @State private var incognitoMode: Bool = false
    @State private var rememberMode: Bool = false
    @State private var rememberTarget: RememberTarget = .domain
    @State private var includeSubdomains: Bool = false

    private var domainForURL: String? {
        url.host?.lowercased()
    }

    private var rootDomainForURL: String? {
        guard let host = url.host else { return nil }
        let parts = host.split(separator: ".")
        guard parts.count >= 2 else { return host }
        return parts.suffix(2).joined(separator: ".")
    }

    private var canRememberForApp: Bool {
        guard let id = sourceAppBundleID, !id.isEmpty else { return false }
        return id != Bundle.main.bundleIdentifier
    }

    private var selectedBrowser: Browser? {
        browsers.first { $0.id == selectedBrowserID }
    }

    private var selectedProfiles: [BrowserProfile] {
        guard let id = selectedBrowserID else { return [] }
        return profiles[id] ?? []
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            browserList

            if selectedBrowserID != nil && !selectedProfiles.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                profilePanel
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .onChange(of: keyboardState.lastAction) { _, action in
            guard let action else { return }
            handleKeyAction(action)
            keyboardState.lastAction = nil
        }
    }

    private func launch(browser: Browser, profile: BrowserProfile?) {
        if rememberMode {
            saveRememberRule(browser: browser, profile: profile)
        }
        onProfileSelected(browser, profile, incognitoMode)
    }

    private func saveRememberRule(browser: Browser, profile: BrowserProfile?) {
        var rules = RuleEngine.loadRules()

        let pattern: String
        let matchType: RuleMatchType
        let sourceApp: String?

        switch rememberTarget {
        case .domain:
            guard let host = domainForURL else { return }
            pattern = includeSubdomains ? (rootDomainForURL ?? host) : host
            matchType = .domain
            sourceApp = nil
        case .sourceApp:
            guard canRememberForApp, let appID = sourceAppBundleID else { return }
            pattern = ""
            matchType = .domain
            sourceApp = appID
        }

        // Conflict: replace any existing rule with the same target
        // (same source app + same pattern) so users don't end up with duplicates.
        rules.removeAll { existing in
            (existing.sourceAppBundleID ?? "") == (sourceApp ?? "") &&
            existing.pattern.lowercased() == pattern.lowercased()
        }

        let newRule = DomainRule(
            pattern: pattern,
            matchType: matchType,
            browserBundleID: browser.bundleID,
            profileDirectory: profile?.directoryName,
            incognito: incognitoMode,
            sourceAppBundleID: sourceApp
        )
        rules.append(newRule)
        RuleEngine.saveRules(rules)
        print("[BrowserPicker] Remembered choice as rule: \(pattern.isEmpty ? "(any URL)" : pattern) → \(browser.name)")
    }

    private func handleKeyAction(_ action: PopupKeyAction) {
        switch action {
        case .selectBrowser(let index):
            if index < browsers.count {
                highlightedIndex = index
                isInProfilePanel = false
                launch(browser: browsers[index], profile: nil)
            }
        case .moveUp:
            if isInProfilePanel {
                highlightedProfileIndex = max(0, highlightedProfileIndex - 1)
            } else {
                highlightedIndex = max(0, highlightedIndex - 1)
            }
        case .moveDown:
            if isInProfilePanel {
                highlightedProfileIndex = min(selectedProfiles.count - 1, highlightedProfileIndex + 1)
            } else {
                highlightedIndex = min(browsers.count - 1, highlightedIndex + 1)
            }
        case .expandProfiles:
            let browser = browsers[highlightedIndex]
            let browserProfiles = profiles[browser.bundleID] ?? []
            if !browserProfiles.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedBrowserID = browser.id
                }
                isInProfilePanel = true
                highlightedProfileIndex = 0
            }
        case .collapseProfiles:
            if isInProfilePanel {
                isInProfilePanel = false
                highlightedProfileIndex = -1
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedBrowserID = nil
                }
            }
        case .confirm:
            if isInProfilePanel && highlightedProfileIndex >= 0 && highlightedProfileIndex < selectedProfiles.count {
                if let browser = selectedBrowser {
                    launch(browser: browser, profile: selectedProfiles[highlightedProfileIndex])
                }
            } else {
                launch(browser: browsers[highlightedIndex], profile: nil)
            }
        case .copyURL:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
            NotificationCenter.default.post(name: .dismissPopup, object: nil)
        case .toggleIncognito:
            incognitoMode.toggle()
        }
    }

    private var browserList: some View {
        VStack(spacing: 0) {
            urlHeader

            if rememberMode {
                Divider()
                rememberStrip
            }

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                        BrowserRowView(
                            browser: browser,
                            hasProfiles: !(profiles[browser.bundleID] ?? []).isEmpty,
                            isSelected: selectedBrowserID == browser.id,
                            isHighlighted: highlightedIndex == index && !isInProfilePanel,
                            index: index,
                            onShowProfiles: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedBrowserID = browser.id
                                    print("[BrowserPicker] Showing profiles for: \(browser.name)")
                                }
                            },
                            onBrowserClicked: {
                                print("[BrowserPicker] Browser clicked: \(browser.name) — using default profile")
                                launch(browser: browser, profile: nil)
                            }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 280)
        .frame(maxHeight: 420)
    }

    private var profilePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let browser = selectedBrowser {
                HStack(spacing: 6) {
                    Image(nsImage: browser.icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(browser.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

                Divider()
                    .padding(.horizontal, 8)
            }

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Array(selectedProfiles.enumerated()), id: \.element.id) { index, profile in
                        ProfileRow(
                            profile: profile,
                            isHighlighted: isInProfilePanel && highlightedProfileIndex == index
                        ) {
                            if let browser = selectedBrowser {
                                print("[BrowserPicker] Profile selected: \(browser.name) → \(profile.name)")
                                launch(browser: browser, profile: profile)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 240)
        .frame(maxHeight: 420)
    }

    private var urlHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(url.absoluteString)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: {
                incognitoMode.toggle()
            }) {
                Image(systemName: incognitoMode ? "eye.slash.fill" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(incognitoMode ? .primary : .tertiary)
            }
            .buttonStyle(.plain)
            .help("Incognito mode (i)")

            Button(action: {
                rememberMode.toggle()
                if rememberMode && !canRememberForApp {
                    rememberTarget = .domain
                }
            }) {
                Image(systemName: rememberMode ? "bookmark.fill" : "bookmark")
                    .font(.caption)
                    .foregroundStyle(rememberMode ? .primary : .tertiary)
            }
            .buttonStyle(.plain)
            .help("Remember next choice as a rule")

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
                NotificationCenter.default.post(name: .dismissPopup, object: nil)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy URL (c)")

            Button(action: {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }) {
                Image(systemName: "gear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

    private var rememberStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(.tint)
                Text("Save next choice as a rule for")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Picker("", selection: $rememberTarget) {
                if let host = domainForURL {
                    Text(includeSubdomains ? "*.\(rootDomainForURL ?? host)" : host).tag(RememberTarget.domain)
                } else {
                    Text("This URL").tag(RememberTarget.domain)
                }
                if canRememberForApp, let name = sourceAppName {
                    Text("Links from \(name)").tag(RememberTarget.sourceApp)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

            if rememberTarget == .domain {
                Toggle(isOn: $includeSubdomains) {
                    Text("Include all subdomains")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.checkbox)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.08))
    }
}

private struct ProfileRow: View {
    let profile: BrowserProfile
    let isHighlighted: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.system(.callout, weight: .medium))

                if let email = profile.email {
                    Text(email)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isHovered || isHighlighted) ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal, 6)
    }
}
