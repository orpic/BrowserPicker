// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct ProfileListView: View {
    let browser: Browser
    let profiles: [BrowserProfile]
    let onProfileSelected: (Browser, BrowserProfile?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(profiles) { profile in
                ProfileRow(profile: profile) {
                    onProfileSelected(browser, profile)
                }
            }
        }
        .padding(.leading, 38)
        .padding(.bottom, 4)
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
        .padding(.trailing, 6)
    }
}
