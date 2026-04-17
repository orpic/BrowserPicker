// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct RouterPopupView: View {
    let url: URL
    let browsers: [Browser]
    let profiles: [String: [BrowserProfile]]
    @ObservedObject var keyboardState: PopupKeyboardState
    let onProfileSelected: (Browser, BrowserProfile?, Bool) -> Void

    @State private var selectedBrowserID: String?
    @State private var highlightedIndex: Int = 0
    @State private var highlightedProfileIndex: Int = -1
    @State private var isInProfilePanel: Bool = false
    @State private var incognitoMode: Bool = false

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

    private func handleKeyAction(_ action: PopupKeyAction) {
        switch action {
        case .selectBrowser(let index):
            if index < browsers.count {
                highlightedIndex = index
                isInProfilePanel = false
                onProfileSelected(browsers[index], nil, incognitoMode)
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
                    onProfileSelected(browser, selectedProfiles[highlightedProfileIndex], incognitoMode)
                }
            } else {
                onProfileSelected(browsers[highlightedIndex], nil, incognitoMode)
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
                                onProfileSelected(browser, nil, incognitoMode)
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
                                onProfileSelected(browser, profile, incognitoMode)
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
