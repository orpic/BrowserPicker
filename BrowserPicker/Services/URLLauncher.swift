// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit
import Foundation

struct URLLauncher {
    static func launch(url: URL, browser: Browser, profile: BrowserProfile?, incognito: Bool = false) {
        switch browser.type {
        case .chromium:
            launchChromium(url: url, browser: browser, profile: profile, incognito: incognito)
        case .firefox:
            launchFirefox(url: url, browser: browser, profile: profile, incognito: incognito)
        case .safari:
            launchSafari(url: url, browser: browser)
        case .unknown:
            launchGeneric(url: url, browser: browser)
        }
    }

    private static func launchChromium(url: URL, browser: Browser, profile: BrowserProfile?, incognito: Bool) {
        var args = [String]()

        if let profile {
            args.append("--profile-directory=\(profile.directoryName)")
        }
        if incognito {
            args.append("--incognito")
        }
        args.append(url.absoluteString)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", "-a", browser.path.path] + ["--args"] + args

        do {
            try task.run()
            let mode = incognito ? " (incognito)" : ""
            print("[BrowserPicker] Launched: \(browser.name) profile=\(profile?.name ?? "default")\(mode) url=\(url.absoluteString)")
        } catch {
            print("[BrowserPicker] Failed to launch \(browser.name): \(error)")
        }
    }

    private static func launchFirefox(url: URL, browser: Browser, profile: BrowserProfile?, incognito: Bool) {
        var args = ["-a", browser.path.path, "--args"]

        if incognito {
            args.append("--private-window")
            args.append(url.absoluteString)
        } else {
            if let profile {
                args.append(contentsOf: ["-P", profile.name])
            }
            args.append(url.absoluteString)
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = args

        do {
            try task.run()
            let mode = incognito ? " (private)" : ""
            print("[BrowserPicker] Launched: \(browser.name) profile=\(profile?.name ?? "default")\(mode) url=\(url.absoluteString)")
        } catch {
            print("[BrowserPicker] Failed to launch \(browser.name): \(error)")
        }
    }

    private static func launchSafari(url: URL, browser: Browser) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", browser.path.path, url.absoluteString]

        do {
            try task.run()
            print("[BrowserPicker] Launched: Safari url=\(url.absoluteString)")
        } catch {
            print("[BrowserPicker] Failed to launch Safari: \(error)")
        }
    }

    private static func launchGeneric(url: URL, browser: Browser) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", browser.path.path, url.absoluteString]

        do {
            try task.run()
            print("[BrowserPicker] Launched: \(browser.name) url=\(url.absoluteString)")
        } catch {
            print("[BrowserPicker] Failed to launch \(browser.name): \(error)")
        }
    }
}
