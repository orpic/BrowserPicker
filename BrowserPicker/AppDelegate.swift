import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private let panelController = FloatingPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )

        panelController.onProfileSelected = { browser, profile in
            if let profile {
                print("[BrowserPicker] Selected: \(browser.name) → \(profile.name)")
            } else {
                print("[BrowserPicker] Selected: \(browser.name) (no profile)")
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        print("[BrowserPicker] Received URL: \(url.absoluteString)")
        showPopup(for: url)
    }

    private func showPopup(for url: URL) {
        let browsers = BrowserDetector.detectInstalledBrowsers()

        var profiles: [String: [BrowserProfile]] = [:]
        for browser in browsers {
            profiles[browser.bundleID] = ProfileDetector.detectProfiles(for: browser)
        }

        panelController.show(url: url, browsers: browsers, profiles: profiles)
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
