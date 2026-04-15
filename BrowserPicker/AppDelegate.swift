import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )
        logDetectedBrowsersAndProfiles()
    }

    private func logDetectedBrowsersAndProfiles() {
        let browsers = BrowserDetector.detectInstalledBrowsers()
        print("[BrowserPicker] === Detected \(browsers.count) browser(s) ===")

        for browser in browsers {
            let profiles = ProfileDetector.detectProfiles(for: browser)
            print("  \(browser.name) (\(browser.bundleID)) — type: \(browser.type.rawValue)")

            if profiles.isEmpty {
                print("    (no profiles)")
            } else {
                for profile in profiles {
                    let emailStr = profile.email.map { " <\($0)>" } ?? ""
                    print("    - \(profile.name)\(emailStr) [dir: \(profile.directoryName)]")
                }
            }
        }

        print("[BrowserPicker] === End browser detection ===")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            print("[BrowserPicker] Received URL: \(url.absoluteString)")
        }
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
