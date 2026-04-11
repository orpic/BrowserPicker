# PLAN — BrowserPicker MVP

Build a native macOS app in Swift/SwiftUI that registers as the default browser, intercepts link clicks, and shows a Spotlight-like floating popup for routing URLs to specific browser profiles. Package as a DMG.

---

## Architecture

```
Link clicked anywhere on macOS
        │
        ▼
App receives URL (onOpenURL)
        │
        ▼
Rule Engine: domain match?
   ├── YES → Launch browser + profile directly
   └── NO  → Show floating popup
                  │
                  ▼
            User picks browser
            (hover expands profiles)
                  │
                  ▼
            Open URL in chosen profile
            (optionally save as domain rule)
```

---

## Project Structure

```
BrowserPicker/                              ← repo root
  BrowserPicker.xcodeproj/                  ← Xcode project (created via Xcode 26.4 wizard)
  BrowserPicker/                            ← source target (Xcode convention)
    BrowserPickerApp.swift                  @main entry (generated), will add onOpenURL handler
    ContentView.swift                       Placeholder (generated), will be replaced
    Assets.xcassets/                        App icon + accent color (generated)
    App/
      AppDelegate.swift                     NSApplicationDelegate, panel management
    Models/
      Browser.swift                         Browser model (name, bundleID, icon, path)
      BrowserProfile.swift                  Profile model (name, directory, email)
      DomainRule.swift                      Domain → browser+profile mapping
    Services/
      BrowserDetector.swift                 Discover installed browsers via NSWorkspace
      ProfileDetector.swift                 Read profiles from Local State / profiles.ini
      URLLauncher.swift                     Open URL in browser+profile via Process/open
      RuleEngine.swift                      Match URL domain against saved rules
      PersistenceService.swift              JSON read/write for rules + preferences
    Views/
      RouterPopup/
        RouterPopupView.swift               Main popup layout
        BrowserRowView.swift                Single browser row with hover state
        ProfileListView.swift               Expanded profile list on hover
      Settings/
        SettingsView.swift                  Settings window
        DomainRulesView.swift               Manage saved domain rules
        OnboardingView.swift                First-launch default browser setup
      Components/
        BrowserIconView.swift               Render browser app icons
    Panel/
      FloatingPanel.swift                   NSPanel subclass (non-activating, floating)
      FloatingPanelController.swift         Show/hide/position logic
    Resources/
      Info.plist                            URL scheme + document type registration
  PRD.md                                    Product requirements
  TECH.md                                   Technical decisions + environment
  PLAN.md                                   This file — build phases + progress
  Scripts/
    build-dmg.sh                            Build release + package into DMG
```

---

## Build Phases

### Phase 0: Environment Setup -- DONE

**Goal:** Get the development environment ready.

- [x] Install Xcode from the Mac App Store — **Xcode 26.4 (Build 17E192)**
- [x] Switch developer tools: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- [x] Accept license: `sudo xcodebuild -license accept`
- [x] Verify: `xcodebuild -version` → Xcode 26.4

### Phase 1: Project Scaffold + Default Browser Registration

**Goal:** App launches, sits in menu bar, and can receive URLs.

- [x] Create new Xcode project (macOS > App > SwiftUI lifecycle) — **done via Xcode 26.4 wizard**
  - Bundle ID: `in.relyx.mac-apps.BrowserPicker`
  - Swift 5.0, SwiftUI, macOS 26.2 deployment target
  - Generated: `BrowserPickerApp.swift`, `ContentView.swift`, `Assets.xcassets`
- [ ] Disable App Sandbox in Xcode build settings (both Debug and Release)
- [ ] Configure `Info.plist`:
  - `CFBundleURLTypes` with `http` and `https` schemes
  - `CFBundleDocumentTypes` for HTML with `LSHandlerRank: Owner`
- [ ] Set `LSUIElement: true` in Info.plist (hides dock icon, menu bar only)
- [ ] Implement `onOpenURL` handler — for now, just log the received URL
- [ ] Add menu bar icon with a basic dropdown (Quit, Settings placeholder)
- [ ] Build and run — verify the app appears in System Settings as a default browser candidate

### Phase 2: Browser + Profile Detection

**Goal:** App can list all installed browsers and their profiles.

- [ ] Implement `BrowserDetector`:
  - Use `NSWorkspace.shared.urlsForApplications(toOpen:)` with HTTP URL
  - Filter against known browser bundle IDs
  - Extract app name and icon from bundle
- [ ] Implement `ProfileDetector` for Chromium family:
  - Read `~/Library/Application Support/<BrowserDir>/Local State`
  - Parse JSON → `.profile.info_cache`
  - Extract profile name, email, directory name
- [ ] Implement `ProfileDetector` for Firefox:
  - Read `~/Library/Application Support/Firefox/profiles.ini`
  - Parse INI sections for profile name and path
- [ ] Handle Safari as profile-less (single entry, no expansion)
- [ ] Handle detection failures gracefully (browser installed but profiles unreadable)

### Phase 3: Floating Popup Panel

**Goal:** Clicking a link shows a Spotlight-like popup with browser + profile selection.

- [ ] Create `FloatingPanel` (NSPanel subclass):
  - Style mask: `.nonActivatingPanel | .titled | .closable | .fullSizeContentView`
  - `isFloatingPanel = true`, `level = .floating`
  - Hidden titlebar, transparent background
  - Override `canBecomeKey` → `true`
- [ ] Create `FloatingPanelController`:
  - Host SwiftUI content via `NSHostingView`
  - Position popup near mouse cursor
  - Show/hide with animation
  - Dismiss on click-outside (`NSEvent.addGlobalMonitorForEvents`)
  - Dismiss on Escape key
- [ ] Build `RouterPopupView`:
  - Show URL being routed at the top
  - List of detected browsers with icons
  - Hover over a browser → expand to show its profiles
  - Click a profile → triggers URL launch
- [ ] Wire up: `onOpenURL` → show popup with the received URL

### Phase 4: URL Launching

**Goal:** Selecting a browser+profile actually opens the URL correctly.

- [ ] Implement `URLLauncher.launch(url:browser:profile:)`:
  - Chromium: `open -n -a "<BrowserName>" --args --profile-directory="<Dir>" "<URL>"`
  - Firefox: `open -a Firefox --args -P "<ProfileName>" "<URL>"`
  - Safari: `open -a Safari "<URL>"`
- [ ] Use `Process` (Foundation) to execute shell commands
- [ ] Dismiss popup after launch
- [ ] Handle launch failures (browser not found, profile deleted)
- [ ] Test with: Chrome, Firefox, Safari, Edge (whatever is installed)

### Phase 5: Domain Rules + Persistence

**Goal:** Users can save "always open X domain in Y profile" rules.

- [ ] Implement `PersistenceService`:
  - Store JSON at `~/Library/Application Support/BrowserPicker/rules.json`
  - Create directory if it doesn't exist
  - Read/write domain rules array
- [ ] Define `DomainRule` model: `domain`, `browserBundleID`, `profileDirectory`, `createdAt`
- [ ] Add "Always open here" checkbox/button in the popup
  - Extracts domain from URL
  - Saves rule on selection
- [ ] Implement `RuleEngine`:
  - On URL received, check domain against saved rules
  - If match found → skip popup, launch directly
  - If no match → show popup as normal
- [ ] Handle subdomain matching (e.g., rule for `github.com` matches `gist.github.com`)

### Phase 6: Settings + Onboarding

**Goal:** Polished settings and first-run experience.

- [ ] Onboarding view (shown on first launch):
  - Explain what the app does
  - Button to open System Settings > Default Browser
  - Detect if already set as default
- [ ] Settings window (from menu bar > Settings):
  - Domain rules list with delete/edit
  - "Launch at login" toggle via `SMAppService.mainApp`
  - "Show in Dock" toggle
  - About section with version
- [ ] Recent choices list (last N routed links with where they went)

### Phase 7: DMG Packaging

**Goal:** Distributable DMG file.

- [ ] Design app icon (or use a clean placeholder)
- [ ] Add icon to `Assets.xcassets`
- [ ] Install `create-dmg`: `brew install create-dmg`
- [ ] Write `Scripts/build-dmg.sh`:
  ```sh
  xcodebuild -scheme BrowserPicker -configuration Release -archivePath build/Release archive
  # Export .app from archive
  create-dmg 'build/Release/BrowserPicker.app' --overwrite
  ```
- [ ] Test: mount DMG, drag to Applications, launch, verify default browser flow

---

## Definition of Done (MVP)

- [ ] App can be set as default browser in System Settings
- [ ] Clicking any link shows the floating popup
- [ ] Popup lists all installed browsers with icons
- [ ] Hovering a browser shows its profiles
- [ ] Clicking a profile opens the URL in that browser+profile
- [ ] "Always open here" saves a domain rule
- [ ] Saved rules bypass the popup on subsequent clicks
- [ ] Settings window allows managing rules
- [ ] App launches at login (optional toggle)
- [ ] Distributable as a DMG
