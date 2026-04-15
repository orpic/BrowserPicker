# BrowserPicker

A macOS utility that intercepts every link you click and lets you choose which browser and profile should open it.

## What it does

When you set BrowserPicker as your default browser, every link click on your Mac (from Mail, Slack, Notes, Terminal, etc.) shows a lightweight popup where you can pick the right browser and profile. No more links opening in the wrong account.

### Supported browsers

- Google Chrome (+ Beta, Dev)
- Firefox
- Safari
- Microsoft Edge
- Brave
- Arc
- Vivaldi
- Opera

Profile detection works for all Chromium-based browsers and Firefox.

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/orpic/BrowserPicker/releases)
2. Open the DMG and drag **BrowserPicker** to your Applications folder
3. Launch BrowserPicker from Applications
4. If macOS shows an "unidentified developer" warning, right-click the app and select **Open**
5. Set BrowserPicker as your default browser in **System Settings > Desktop & Dock > Default web browser**

## How it works

- Registers as a default browser candidate via `CFBundleURLTypes` (http/https schemes)
- Detects installed browsers using `NSWorkspace`
- Reads browser profiles from Chromium `Local State` JSON and Firefox `profiles.ini`
- Shows a floating `NSPanel` popup (non-activating, doesn't steal focus)
- Launches the selected browser + profile via `/usr/bin/open` with the appropriate flags

## Building from source

Requires Xcode 26+ and macOS 26+.

```bash
# Clone
git clone https://github.com/orpic/BrowserPicker.git
cd BrowserPicker

# Open in Xcode
open BrowserPicker.xcodeproj

# Or build a DMG (requires create-dmg: brew install create-dmg)
./Scripts/build-release.sh 1.0.0
```

## License

**This is not open source software.** The source code is publicly visible for transparency only.

- Free for personal download and use
- No commercial use
- No redistribution of the app or source code
- No derivative works

See [LICENSE](LICENSE) for full terms. Only the [GitHub Releases page](https://github.com/orpic/BrowserPicker/releases) link may be shared.
