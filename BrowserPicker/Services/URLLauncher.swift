import AppKit

struct URLLauncher {
    static func launch(url: URL, browser: Browser, profile: BrowserProfile?) {
        switch browser.type {
        case .chromium:
            launchChromium(url: url, browser: browser, profile: profile)
        case .firefox:
            launchFirefox(url: url, browser: browser, profile: profile)
        case .safari:
            launchSafari(url: url, browser: browser)
        case .unknown:
            launchGeneric(url: url, browser: browser)
        }
    }

    private static func launchChromium(url: URL, browser: Browser, profile: BrowserProfile?) {
        var args = [String]()

        if let profile {
            args.append("--profile-directory=\(profile.directoryName)")
        }
        args.append(url.absoluteString)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", "-a", browser.path.path] + ["--args"] + args

        do {
            try task.run()
            print("[BrowserPicker] Launched: \(browser.name) profile=\(profile?.name ?? "default") url=\(url.absoluteString)")
        } catch {
            print("[BrowserPicker] Failed to launch \(browser.name): \(error)")
        }
    }

    private static func launchFirefox(url: URL, browser: Browser, profile: BrowserProfile?) {
        var args = ["-a", browser.path.path, "--args"]

        if let profile {
            args.append(contentsOf: ["-P", profile.name])
        }
        args.append(url.absoluteString)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = args

        do {
            try task.run()
            print("[BrowserPicker] Launched: \(browser.name) profile=\(profile?.name ?? "default") url=\(url.absoluteString)")
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
