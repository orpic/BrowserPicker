// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct RouterPopupView: View {
    let url: URL
    let browsers: [Browser]
    let profiles: [String: [BrowserProfile]]
    let onProfileSelected: (Browser, BrowserProfile?) -> Void

    @State private var selectedBrowserID: String?

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
    }

    private var browserList: some View {
        VStack(spacing: 0) {
            urlHeader

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(browsers) { browser in
                        BrowserRowView(
                            browser: browser,
                            hasProfiles: !(profiles[browser.bundleID] ?? []).isEmpty,
                            isSelected: selectedBrowserID == browser.id,
                            onShowProfiles: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedBrowserID = browser.id
                                    print("[BrowserPicker] Showing profiles for: \(browser.name)")
                                }
                            },
                            onBrowserClicked: {
                                print("[BrowserPicker] Browser clicked: \(browser.name) — using default profile")
                                onProfileSelected(browser, nil)
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
                    ForEach(selectedProfiles) { profile in
                        ProfileRow(profile: profile) {
                            if let browser = selectedBrowser {
                                print("[BrowserPicker] Profile selected: \(browser.name) → \(profile.name)")
                                onProfileSelected(browser, profile)
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct ProfileRow: View {
    let profile: BrowserProfile
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
        .background(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
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
