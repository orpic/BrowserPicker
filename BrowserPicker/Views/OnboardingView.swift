// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Welcome to BrowserPicker")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                feature(icon: "link", text: "Intercepts every link you click on your Mac")
                feature(icon: "list.bullet", text: "Shows all your browsers and profiles in a popup")
                feature(icon: "person.2", text: "Open links in the right browser profile every time")
            }
            .padding(.horizontal, 8)

            Divider()

            VStack(spacing: 8) {
                Text("To get started, set BrowserPicker as your default browser:")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Got it") {
                onDismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 420, height: 400)
    }

    private func feature(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.tint)
            Text(text)
                .font(.callout)
        }
    }
}
