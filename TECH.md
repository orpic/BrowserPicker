# TECH — BrowserPicker

Technical decisions, environment, and rationale for the BrowserPicker macOS app.

---

## Development Environment

### Current State (as of 2026-04-11)

| Component | Status | Version / Detail |
|---|---|---|
| macOS | Ready | 26.2 (Tahoe), arm64 |
| Swift toolchain | Ready | 6.1.2 (swiftlang-6.1.2.1.2) |
| Xcode | Ready | 26.4 (Build 17E192) |
| Homebrew | Ready | 5.1.3 |
| `create-dmg` | Not installed | Needed for Phase 7 (DMG packaging) |

### Setup Steps Completed

1. **Xcode** installed from the Mac App Store (26.4).

2. Switched active developer directory:
   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

3. Accepted the Xcode license:
   ```sh
   sudo xcodebuild -license accept
   ```

4. **Xcode project created** via File > New > Project > macOS > App (SwiftUI).

### Remaining Setup (Phase 7)

5. Install `create-dmg` (needed for DMG packaging):
   ```sh
   brew install create-dmg
   ```

### Apple Developer Account

**Not required** for local development and testing. Only needed if we want to:
- Notarize the app (required for distributing to others without Gatekeeper warnings)
- Distribute via the Mac App Store

For MVP, we skip notarization. Users can right-click > Open to bypass Gatekeeper.

---

## Xcode Project Details

Values from the generated `project.pbxproj` (Xcode 26.4):

| Setting | Value |
|---|---|
| Project format (`objectVersion`) | 77 |
| `CreatedOnToolsVersion` | 26.4 |
| `MACOSX_DEPLOYMENT_TARGET` | 26.2 (matches dev machine; lower later if targeting older macOS) |
| `SWIFT_VERSION` | 5.0 (Xcode default; Swift 6 strict concurrency is opt-in) |
| `PRODUCT_BUNDLE_IDENTIFIER` | `in.relyx.mac-apps.BrowserPicker` |
| `MARKETING_VERSION` | 1.0 |
| `CURRENT_PROJECT_VERSION` | 1 |
| `ENABLE_APP_SANDBOX` | YES (**must be disabled** — see note below) |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | MainActor |
| `SWIFT_APPROACHABLE_CONCURRENCY` | YES |
| `CODE_SIGN_STYLE` | Automatic |

### Generated Source Files

```
BrowserPicker/
  BrowserPickerApp.swift          @main entry point (SwiftUI App lifecycle)
  ContentView.swift               Placeholder "Hello, world!" view
  Assets.xcassets/
    AccentColor.colorset/
    AppIcon.appiconset/
```

### Sandbox Must Be Disabled

Xcode enables `ENABLE_APP_SANDBOX = YES` by default. We need to turn this **off** in Xcode build settings (both Debug and Release) because the app reads browser profile data from:

- `~/Library/Application Support/Google/Chrome/Local State`
- `~/Library/Application Support/Firefox/profiles.ini`
- Similar paths for Edge, Brave, Arc, Vivaldi

These paths are inaccessible under App Sandbox. Since we distribute via DMG (not Mac App Store), sandboxing is not required.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 5.0 (Xcode default) | Xcode 26.4 sets Swift language version to 5.0. Swift 6 strict concurrency can be opted into later. The Swift toolchain itself is 6.1.2. |
| UI Framework | SwiftUI | Apple's modern declarative UI framework. Less boilerplate than AppKit. |
| AppKit Bridging | NSPanel subclass | SwiftUI alone can't create non-activating floating panels. We bridge to AppKit for the popup window only. |
| Min Deployment Target | macOS 26.2 (Tahoe) | Xcode defaulted to the dev machine's OS version. Can be lowered to macOS 14 (Sonoma) later if we want broader compatibility. |
| Build System | Xcode + SPM | Standard Apple toolchain. SPM for any external dependencies. |
| Data Persistence | JSON files | Simple, debuggable, no CoreData overhead for MVP. Stored in `~/Library/Application Support/BrowserPicker/`. |
| DMG Packaging | `create-dmg` (Homebrew) | Shell-script tool that produces professional DMGs with Applications folder shortcut. |

---

## Key Technical Decisions

### 1. Why SwiftUI + AppKit Bridging (not pure AppKit or Electron)

SwiftUI is Apple's direction for all new macOS development. It handles 90% of our UI needs (settings, lists, hover states) with far less code than AppKit. The one exception is the floating popup — SwiftUI windows activate the app and steal focus, which breaks the "zero interruption" UX principle. For that single component, we subclass `NSPanel` from AppKit and host SwiftUI content inside it via `NSHostingView`.

This gives us the best of both worlds: fast SwiftUI development + precise window behavior control where it matters.

### 2. Why NSPanel (not NSWindow or SwiftUI Window)

The popup must behave like Spotlight/Raycast:
- Appear instantly without activating the app
- Float above all other windows
- Not steal focus from the app where the user clicked the link
- Dismiss when clicking outside

`NSPanel` with `.nonActivatingPanel` style mask is the only way to achieve this on macOS. Standard `NSWindow` and SwiftUI `Window` both activate the application, which would pull the user out of their current context.

### 3. Why Non-Sandboxed

The app needs to read browser profile data from:
- `~/Library/Application Support/Google/Chrome/Local State`
- `~/Library/Application Support/Firefox/profiles.ini`
- Similar paths for Edge, Brave, Arc, Vivaldi

macOS App Sandbox restricts access to these paths. Since we're distributing via DMG (not the Mac App Store), sandboxing is not required. This simplifies development significantly.

If we ever target the Mac App Store, we'd need to rethink profile detection (possibly using a helper tool with a temporary exception entitlement).

### 4. Why JSON Persistence (not CoreData, SwiftData, or UserDefaults)

Domain rules and preferences are simple key-value data. JSON files are:
- Human-readable and debuggable
- Easy to back up, share, or reset
- No migration complexity
- Sufficient for the expected data volume (hundreds of rules at most)

CoreData/SwiftData would be overkill. UserDefaults has size limits and is harder to inspect.

### 5. Deployment Target Consideration

Xcode defaulted `MACOSX_DEPLOYMENT_TARGET` to 26.2 (the dev machine's OS). This means the app will only run on macOS 26.2+. If we want to support older macOS versions (e.g., macOS 14 Sonoma), we can lower this in Xcode build settings later. For MVP, 26.2 is fine since we're building for personal use first.

### 6. How Default Browser Registration Works

macOS routes `http://` and `https://` links to the "default browser." To register as a candidate:

1. Declare `CFBundleURLTypes` in `Info.plist` for `http` and `https` schemes
2. Declare `CFBundleDocumentTypes` for HTML content with `LSHandlerRank: Owner`
3. The user then selects our app in System Settings > Desktop & Dock > Default web browser

Once set, every link click system-wide (from Mail, Slack, Terminal, etc.) is routed to our app's `onOpenURL` handler.

### 7. How Browser Detection Works

`NSWorkspace.shared.urlsForApplications(toOpen:)` returns all apps registered to handle a given URL type. We call it with an `http://` URL, then filter results against a known list of browser bundle IDs to exclude non-browser apps that register as URL handlers (e.g., iTerm2, various dev tools).

Known browser bundle IDs we track:

| Browser | Bundle ID |
|---|---|
| Safari | `com.apple.Safari` |
| Chrome | `com.google.Chrome` |
| Chrome Beta | `com.google.Chrome.beta` |
| Chrome Dev | `com.google.Chrome.dev` |
| Firefox | `org.mozilla.firefox` |
| Edge | `com.microsoft.edgemac` |
| Brave | `com.brave.Browser` |
| Arc | `company.thebrowser.Browser` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Opera | `com.operasoftware.Opera` |

### 8. How Profile Detection Works

**Chromium-based browsers** (Chrome, Edge, Brave, Arc, Vivaldi):
- Read `~/Library/Application Support/<BrowserDir>/Local State`
- Parse JSON, navigate to `.profile.info_cache`
- Each key is a profile directory name (`Default`, `Profile 1`, etc.)
- Each value contains `name` (display name), `user_name` (email), `gaia_given_name`

**Firefox:**
- Read `~/Library/Application Support/Firefox/profiles.ini`
- Parse INI format, each `[Profile<N>]` section has `Name` and `Path` fields

**Safari:**
- No profile support. Shown as a single entry.

### 9. How URL Launching Works

Each browser family requires different command-line flags to target a specific profile:

**Chromium-based:**
```sh
open -n -a "Google Chrome" --args --profile-directory="Profile 1" "https://example.com"
```
The `-n` flag opens a new instance if Chrome is already running with a different profile.

**Firefox:**
```sh
open -a Firefox --args -P "profile-name" "https://example.com"
```

**Safari:**
```sh
open -a Safari "https://example.com"
```

---

## Chromium Browser Data Paths

| Browser | Application Support Directory |
|---|---|
| Chrome | `Google/Chrome` |
| Chrome Beta | `Google/Chrome Beta` |
| Chrome Dev | `Google/Chrome Dev` |
| Edge | `Microsoft Edge` |
| Brave | `BraveSoftware/Brave-Browser` |
| Arc | `Arc` |
| Vivaldi | `Vivaldi` |

All relative to `~/Library/Application Support/`.

---

## Existing Prior Art on This Machine

**Browserosaurus** is installed at `/Applications/Browserosaurus.app`. It's an existing browser chooser app but is **not profile-aware** — it only lets you pick a browser, not a specific profile within that browser. Our app's core differentiator is profile-level routing.

---

## Future Considerations (Post-MVP)

- **Notarization:** Required for frictionless distribution. Needs an Apple Developer account ($99/year).
- **Auto-update:** Consider Sparkle framework for in-app updates.
- **App Sandbox:** Required if we ever target the Mac App Store. Would need entitlement exceptions for reading browser data.
- **Swift 6 strict concurrency:** Xcode set `SWIFT_VERSION = 5.0`. Adopt Swift 6 language mode and full `Sendable` / actor isolation once the codebase stabilizes.
