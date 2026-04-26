// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let panelController = FloatingPanelController()
    private var pendingURL: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteURL(_:)),
            name: .routeURL,
            object: nil
        )

        panelController.onProfileSelected = { [weak self] browser, profile, incognito in
            guard let self, let url = self.pendingURL else { return }
            URLLauncher.launch(url: url, browser: browser, profile: profile, incognito: incognito)
            HistoryService.log(url: url, browser: browser, profile: profile, incognito: incognito)
            self.pendingURL = nil
        }

        showOnboardingIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            handleOpenSettings()
        }
        return true
    }

    private func showOnboardingIfNeeded() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        guard !hasSeenOnboarding else { return }

        let onboardingView = OnboardingView {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            self.onboardingWindow?.close()
            self.onboardingWindow = nil
        }

        let hostingView = NSHostingView(rootView: onboardingView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to BrowserPicker"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self

        onboardingWindow = window

        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                window.level = .normal
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let rawURL = urls.first else { return }

        // Handle .browserpicker config files opened from Finder by routing
        // them to the import flow rather than the URL launcher.
        if rawURL.isFileURL && rawURL.pathExtension.lowercased() == "browserpicker" {
            handleConfigFileOpen(rawURL)
            return
        }

        // Capture the source app synchronously, before any other work — the
        // frontmost app at this moment is almost always the app the user
        // clicked the link in.
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceAppBundleID = sourceApp?.bundleIdentifier
        print("[BrowserPicker] Received URL: \(rawURL.absoluteString) from: \(sourceAppBundleID ?? "unknown")")

        let url = URLRewriter.rewrite(rawURL)

        if let match = RuleEngine.match(url: url, sourceAppBundleID: sourceAppBundleID) {
            let browsers = BrowserDetector.detectInstalledBrowsers()
            if let browser = browsers.first(where: { $0.bundleID == match.browserBundleID }) {
                let profile: BrowserProfile?
                if let profileDir = match.profileDirectory {
                    profile = ProfileDetector.detectProfiles(for: browser).first { $0.directoryName == profileDir }
                } else {
                    profile = nil
                }
                print("[BrowserPicker] Rule matched: \(match.rule.pattern) → \(browser.name)")
                URLLauncher.launch(url: url, browser: browser, profile: profile, incognito: match.incognito)
                HistoryService.log(url: url, browser: browser, profile: profile, incognito: match.incognito, viaRule: true)
                return
            }
        }

        showPopup(for: url, sourceApp: sourceApp)
    }

    private func showPopup(for url: URL, sourceApp: NSRunningApplication?) {
        pendingURL = url
        let browsers = BrowserDetector.detectInstalledBrowsers()

        var profiles: [String: [BrowserProfile]] = [:]
        for browser in browsers {
            profiles[browser.bundleID] = ProfileDetector.detectProfiles(for: browser)
        }

        panelController.show(url: url, browsers: browsers, profiles: profiles, sourceApp: sourceApp)
    }

    @objc private func handleRouteURL(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }
        // The user explicitly requested the picker (e.g. from the History tab).
        // Skip rule matching so they always get to choose.
        showPopup(for: url, sourceApp: nil)
    }

    private func handleConfigFileOpen(_ fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let package = try ConfigService.decode(data)
            presentImportPrompt(for: package, sourceFilename: fileURL.lastPathComponent)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not import configuration"
            alert.informativeText = "The file \(fileURL.lastPathComponent) could not be read: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    private func presentImportPrompt(for package: ConfigPackage, sourceFilename: String) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Import \(sourceFilename)?"
        var details = "\(package.rules.count) rule(s), \(package.rewrites.count) rewrite(s)"
        if let history = package.history, !history.isEmpty {
            details += ", \(history.count) history entries (not applied)"
        }
        details += "\nExported from BrowserPicker v\(package.appVersion)."
        details += "\n\nReplace All wipes your existing rules and rewrites. Merge keeps yours and skips duplicates."
        alert.informativeText = details
        alert.addButton(withTitle: "Replace All")
        alert.addButton(withTitle: "Merge")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            let summary = ConfigService.apply(package, strategy: .replace)
            showImportSummary(summary, strategy: .replace)
        case .alertSecondButtonReturn:
            let summary = ConfigService.apply(package, strategy: .merge)
            showImportSummary(summary, strategy: .merge)
        default:
            break
        }
    }

    private func showImportSummary(_ summary: ImportSummary, strategy: ImportStrategy) {
        let alert = NSAlert()
        alert.messageText = "Import complete"
        switch strategy {
        case .replace:
            alert.informativeText = "Replaced existing configuration.\nRules: \(summary.rulesAdded), Rewrites: \(summary.rewritesAdded)"
        case .merge:
            alert.informativeText = "Merged into existing configuration.\nRules added: \(summary.rulesAdded) (skipped \(summary.rulesSkipped))\nRewrites added: \(summary.rewritesAdded) (skipped \(summary.rewritesSkipped))"
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func handleOpenSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "BrowserPicker Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.delegate = self

        settingsWindow = window

        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                window.level = .normal
            }
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let visibleWindows = NSApp.windows.filter { $0.isVisible && !$0.title.isEmpty }
            if visibleWindows.isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
