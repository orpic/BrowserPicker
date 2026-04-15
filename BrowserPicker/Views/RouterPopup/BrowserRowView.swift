// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct BrowserRowView: View {
    let browser: Browser
    let hasProfiles: Bool
    let isSelected: Bool
    let onShowProfiles: () -> Void
    let onBrowserClicked: () -> Void

    @State private var isRowHovered = false
    @State private var isChevronHovered = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: browser.icon)
                    .resizable()
                    .frame(width: 28, height: 28)

                Text(browser.name)
                    .font(.system(.body, weight: .medium))

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onBrowserClicked()
            }

            if hasProfiles {
                Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(isChevronHovered || isSelected ? .primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(isChevronHovered ? Color.primary.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isChevronHovered = hovering
                        if hovering {
                            onShowProfiles()
                        }
                    }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isRowHovered ? Color.primary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isRowHovered = hovering
        }
        .padding(.horizontal, 6)
    }
}
