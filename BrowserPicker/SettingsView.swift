// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var isDefaultBrowser = false

    var body: some View {
        VStack(spacing: 0) {
            aboutSection

            Divider()
                .padding(.horizontal, 20)

            settingsSection

            Divider()
                .padding(.horizontal, 20)

            defaultBrowserSection
        }
        .padding(.vertical, 20)
        .frame(width: 420, height: 340)
        .onAppear {
            checkDefaultBrowser()
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .imageScale(.large)
                .font(.system(size: 36))
                .foregroundStyle(.tint)

            Text("BrowserPicker")
                .font(.title2.bold())

            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Link("GitHub", destination: URL(string: "https://github.com/orpic/BrowserPicker")!)
                .font(.caption)
        }
        .padding(.bottom, 16)
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
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
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
        .padding(.vertical, 16)
    }

    private func checkDefaultBrowser() {
        if let defaultBrowser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) {
            let bundleID = Bundle(url: defaultBrowser)?.bundleIdentifier
            isDefaultBrowser = bundleID == Bundle.main.bundleIdentifier
        }
    }
}
