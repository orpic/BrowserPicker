# TECH — BrowserPicker

Technical decisions, environment, and architecture for the BrowserPicker macOS app.

---

## Development Environment

| Component | Version / Detail |
|---|---|
| macOS | 26.2 (Tahoe), arm64 |
| Swift toolchain | 6.1.2 (swiftlang-6.1.2.1.2) |
| Swift language version | 5.0 (Xcode default) |
| Xcode | 26.4 (Build 17E192) |
| Min deployment target | macOS 14.6 (Sonoma) |
| Homebrew | 5.1.3 |
| `create-dmg` | Required for DMG packaging |

---

## Xcode Project Details

| Setting | Value |
|---|---|
| Project format (`objectVersion`) | 77 |
| `PRODUCT_BUNDLE_IDENTIFIER` | `in.relyx.mac-apps.BrowserPicker` |
| `MARKETING_VERSION` | 1.0 |
| `CURRENT_PROJECT_VERSION` | 2 |
| `ENABLE_APP_SANDBOX` | NO |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | MainActor |
| `CODE_SIGN_STYLE` | Automatic (Apple ID) |
| `GENERATE_INFOPLIST_FILE` | NO (custom Info.plist) |

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 5.0 | Xcode 26.4 default. Swift 6 strict concurrency opt-in later. |
| UI Framework | SwiftUI | Modern declarative UI for settings, popup content, onboarding. |
| AppKit Bridging | NSPanel + NSHostingView | Floating popup requires non-activating panel. NSWindow for settings (workaround for macOS Tahoe SwiftUI window bugs). |
| Min Deployment Target | macOS 14.6 (Sonoma) | Covers 2+ major versions back. All SwiftUI APIs we use are available. |
| Build System | Xcode + SPM | Standard Apple toolchain. |
| Data Persistence | JSON files | `~/Library/Application Support/BrowserPicker/` — rules.json, rewrite-rules.json, history.json. |
| DMG Packaging | `create-dmg` (Homebrew) | Professional DMGs with Applications folder shortcut. |

---

## Architecture

```
BrowserPicker/
  BrowserPickerApp.swift              @main, MenuBarExtra, AppDelegate adaptor
  AppDelegate.swift                   URL handling, rule matching, popup/settings/onboarding windows
  MenuBarView.swift                   Menu bar dropdown (Settings, Quit)
  ContentView.swift                   Placeholder (unused)
  SettingsView.swift                  Tabbed settings (General, Rules, Rewrite, History)
  Models/
    Browser.swift                     Browser, BrowserType, BrowserInfo, known bundle IDs
    BrowserProfile.swift              Profile model (name, directory, email)
    DomainRule.swift                  Rule model (pattern, match type, browser, profile, incognito)
    RewriteRule.swift                 URL rewrite model (regex pattern, replacement)
    HistoryEntry.swift                Link history entry (url, browser, profile, timestamp)
  Services/
    BrowserDetector.swift             NSWorkspace-based browser discovery
    ProfileDetector.swift             Chromium Local State JSON + Firefox profiles.ini parser
    URLLauncher.swift                 Launch URL in browser+profile via /usr/bin/open
    RuleEngine.swift                  Domain/glob/regex rule matching
    URLRewriter.swift                 Regex-based URL transformation
    PersistenceService.swift          JSON read/write to Application Support
    HistoryService.swift              Link history logging (capped at 500)
  Panel/
    FloatingPanel.swift               NSPanel subclass (non-activating, borderless, floating)
    FloatingPanelController.swift     Show/dismiss/position popup near mouse cursor
    PopupKeyboardState.swift          Keyboard action bridge (NSPanel → SwiftUI)
  Views/
    OnboardingView.swift              First-launch welcome with default browser setup
    RouterPopup/
      RouterPopupView.swift           Main popup: URL header, browser list, profile side panel
      BrowserRowView.swift            Browser row with icon, name, index, chevron
      ProfileListView.swift           Profile sub-list (legacy, may be unused)
  Info.plist                          URL schemes, document types, LSUIElement, bundle version
  Assets.xcassets/                    App icon, accent color
```

---

## URL Routing Flow

1. macOS sends URL to `AppDelegate.application(_:open:)`
2. `URLRewriter.rewrite()` transforms URL (if rewrite rules match)
3. `RuleEngine.match()` checks domain/URL rules
4. If rule matches → `URLLauncher.launch()` directly, log to `HistoryService`
5. If no match → show floating popup via `FloatingPanelController`
6. User selects browser+profile → `URLLauncher.launch()`, log to `HistoryService`

---

## Key Technical Decisions

### 1. Why NSPanel (not NSWindow or SwiftUI Window)

The popup must not steal focus from the app where the user clicked the link. `NSPanel` with `.nonactivatingPanel` style mask is the only way to achieve this. SwiftUI `Window` and `openWindow` have bugs on macOS Tahoe that prevent them from appearing reliably in menu bar apps.

### 2. Why Non-Sandboxed

The app reads browser profile data from:
- `~/Library/Application Support/Google/Chrome/Local State`
- `~/Library/Application Support/Firefox/profiles.ini`
- Similar paths for Edge, Brave, Arc, Vivaldi

App Sandbox blocks these paths. Distributed via DMG, not Mac App Store.

### 3. Settings Window via NSWindow (not SwiftUI Settings scene)

SwiftUI's `Settings` scene and `openSettings()` don't work on macOS Tahoe for menu bar apps. We create `NSWindow` with `NSHostingView` directly, with activation policy juggling (`.regular` when settings opens, `.accessory` when it closes).

### 4. JSON Persistence

Domain rules, rewrite rules, and history are simple JSON files. Human-readable, no migration complexity, sufficient for the data volume.

### 5. Keyboard Bridging via PopupKeyboardState

`NSPanel.keyDown` captures key events in AppKit. `PopupKeyboardState` (ObservableObject) bridges them to SwiftUI via `@ObservedObject` + `onChange`. This avoids focus issues with SwiftUI's native keyboard handling in non-activating panels.

---

## Browser Detection

`NSWorkspace.shared.urlsForApplications(toOpen:)` with an HTTP URL, filtered against known bundle IDs:

| Browser | Bundle ID | Type | App Support Dir |
|---|---|---|---|
| Safari | `com.apple.Safari` | safari | — |
| Chrome | `com.google.Chrome` | chromium | `Google/Chrome` |
| Chrome Beta | `com.google.Chrome.beta` | chromium | `Google/Chrome Beta` |
| Chrome Dev | `com.google.Chrome.dev` | chromium | `Google/Chrome Dev` |
| Firefox | `org.mozilla.firefox` | firefox | `Firefox` |
| Edge | `com.microsoft.edgemac` | chromium | `Microsoft Edge` |
| Brave | `com.brave.Browser` | chromium | `BraveSoftware/Brave-Browser` |
| Arc | `company.thebrowser.Browser` | chromium | `Arc` |
| Vivaldi | `com.vivaldi.Vivaldi` | chromium | `Vivaldi` |
| Opera | `com.operasoftware.Opera` | chromium | `com.operasoftware.Opera` |

---

## Profile Detection

**Chromium:** Read `~/Library/Application Support/<dir>/Local State`, parse JSON → `profile.info_cache`. Each key is a profile directory, value has `name`, `user_name`, `gaia_given_name`.

**Firefox:** Parse `~/Library/Application Support/Firefox/profiles.ini` INI format. Each `[ProfileN]` section has `Name` and `Path`.

**Safari:** No profile support. Single entry, no expansion.

---

## URL Launching

| Browser Type | Command |
|---|---|
| Chromium | `open -n -a "<App>" --args --profile-directory="<Dir>" [--incognito] "<URL>"` |
| Firefox | `open -a Firefox --args -P "<Name>" "<URL>"` or `--private-window "<URL>"` |
| Safari | `open -a Safari "<URL>"` |

---

## Distribution

- **Code signing:** Apple ID (free, not Developer ID)
- **Notarization:** None (users right-click > Open on first launch)
- **Packaging:** `create-dmg` via `Scripts/build-release.sh`
- **Release:** Git tag push triggers GitHub Actions to create a release page; DMG built locally and uploaded manually
- **License:** Proprietary source-available (see LICENSE)
