# PLAN — BrowserPicker

Build log and status for the BrowserPicker macOS app.

---

## Completed Phases

### Phase 0: Environment Setup — DONE

- [x] Xcode 26.4 installed
- [x] Developer tools switched and license accepted

### Phase 1: Project Scaffold + Default Browser Registration — DONE

- [x] Xcode project created via wizard (SwiftUI, macOS)
- [x] Bundle ID: `in.relyx.mac-apps.BrowserPicker`
- [x] Disabled App Sandbox
- [x] Custom Info.plist with HTTP/HTTPS URL schemes, HTML/XHTML document types
- [x] LSUIElement = true (menu bar only, no dock icon)
- [x] MenuBarExtra with globe icon (Settings, Quit)
- [x] AppDelegate handles incoming URLs
- [x] Settings window via NSWindow + NSHostingView (workaround for macOS Tahoe SwiftUI bugs)
- [x] Dock icon appears only when settings is open
- [x] App appears as default browser candidate in System Settings

### Phase 2: Browser + Profile Detection — DONE

- [x] BrowserDetector using NSWorkspace to find installed browsers
- [x] Known browser bundle ID map (Chrome, Chrome Beta, Chrome Dev, Firefox, Edge, Brave, Arc, Vivaldi, Opera, Safari)
- [x] ProfileDetector for Chromium (Local State JSON) and Firefox (profiles.ini)
- [x] Safari handled as profile-less

### Phase 3: Floating Popup Panel — DONE

- [x] FloatingPanel (NSPanel subclass) — non-activating, borderless, floating
- [x] FloatingPanelController — show near mouse, dismiss on click-outside/Escape
- [x] RouterPopupView — URL header + browser list
- [x] Profile side panel via chevron hover (replaces inline expand to avoid flicker)
- [x] Screen edge positioning accounts for expanded width

### Phase 4: URL Launching — DONE

- [x] URLLauncher for Chromium (--profile-directory), Firefox (-P), Safari, generic
- [x] Incognito/private mode (--incognito, --private-window)
- [x] Wired into AppDelegate via popup callback

### Phase 5: Domain Rules + URL Patterns + URL Rewriting — DONE

- [x] DomainRule model with domain, glob, regex match types
- [x] RuleEngine matches URLs against saved rules
- [x] Matched URLs bypass popup, launch directly
- [x] RewriteRule model for regex-based URL transformation
- [x] URLRewriter applied before rule matching
- [x] PersistenceService for JSON read/write to Application Support
- [x] Settings > Rules tab with add/delete/toggle
- [x] Settings > Rewrite tab with add/delete/toggle

### Phase 6: Settings + Onboarding — DONE

- [x] Tabbed settings: General, Rules, Rewrite, History
- [x] About section with version and GitHub link
- [x] Launch at login toggle (SMAppService)
- [x] Default browser status indicator
- [x] OnboardingView on first launch
- [x] Settings accessible from Spotlight/Finder via applicationShouldHandleReopen

### Phase 7: Distribution — DONE

- [x] Scripts/build-release.sh for local DMG packaging
- [x] GitHub Actions workflow creates release page with auto-generated changelog on tag push
- [x] DMG built locally (signed with Apple ID) and uploaded to release
- [x] Proprietary LICENSE file
- [x] README with install instructions, features, release process
- [x] Deployment target lowered to macOS 14.6 (Sonoma)

---

## Additional Features Shipped (v1.1)

- [x] Copy URL button in popup (also via `c` key)
- [x] Keyboard shortcuts (1-9, arrows, Enter, c, i, Escape)
- [x] Incognito/private mode toggle in popup (also via `i` key)
- [x] Link history log (500 entries, searchable, Settings > History)
- [x] Gear icon in popup header for quick settings access
- [x] Browser row number indices for keyboard reference

---

## Project Structure

```
BrowserPicker/                          repo root
  BrowserPicker.xcodeproj/              Xcode project
  BrowserPicker/                        source target
    BrowserPickerApp.swift              @main, MenuBarExtra
    AppDelegate.swift                   URL routing, windows, onboarding
    MenuBarView.swift                   Menu bar dropdown
    ContentView.swift                   Placeholder
    SettingsView.swift                  Tabbed settings (General, Rules, Rewrite, History)
    Models/
      Browser.swift                     Browser model + known bundle IDs
      BrowserProfile.swift              Profile model
      DomainRule.swift                  Routing rule model
      RewriteRule.swift                 URL rewrite model
      HistoryEntry.swift                History entry model
    Services/
      BrowserDetector.swift             Browser discovery
      ProfileDetector.swift             Profile reading (Chromium + Firefox)
      URLLauncher.swift                 URL launching with profile + incognito
      RuleEngine.swift                  Domain/URL rule matching
      URLRewriter.swift                 URL transformation
      PersistenceService.swift          JSON persistence
      HistoryService.swift              Link history
    Panel/
      FloatingPanel.swift               NSPanel subclass
      FloatingPanelController.swift     Popup lifecycle
      PopupKeyboardState.swift          Keyboard bridge
    Views/
      OnboardingView.swift              First-launch welcome
      RouterPopup/
        RouterPopupView.swift           Main popup view
        BrowserRowView.swift            Browser row
        ProfileListView.swift           Profile list
    Assets.xcassets/                    Icons
    Info.plist                          URL schemes, LSUIElement, bundle version
  Scripts/
    build-release.sh                    DMG packaging
  .github/workflows/
    release.yml                         GitHub Release on tag push
  PRD.md
  TECH.md
  PLAN.md                              This file
  README.md
  LICENSE
```
