# PRD — BrowserPicker for macOS

## 1) Product Summary

A macOS default-browser utility that intercepts every clicked web link and lets the user choose **which browser and which browser profile** should open it.

The product's core value is **intentional link routing without browser friction**.

Instead of forcing users to manually switch browsers or profiles, the app presents a lightweight floating popup showing available browsers, with profiles accessible via a side panel. Users can also set up domain rules for automatic routing, rewrite URLs before opening, and browse their link history.

This allows users to separate:

- work vs personal accounts
- multiple client accounts
- test environments
- social vs productivity browsing
- secure vs disposable sessions

The long-term vision is to become the **smart traffic controller for all web links on macOS**.

---

## 2) Problem Statement

Users who operate across multiple browsers and multiple profiles face constant friction:

- links open in the wrong account
- SSO sessions conflict
- client work leaks into personal sessions
- meeting links open in the wrong workspace
- dev/staging/admin links open in incorrect authenticated contexts
- repeated manual browser switching wastes time

Existing solutions are either:

- browser-only
- app-based but not profile-aware enough
- too many clicks
- not optimized for fast keyboard workflows

The missing experience is **profile-first link intent selection**.

---

## 3) Target Users

### Primary

- product engineers
- consultants
- agency developers
- founders
- growth teams
- customer success teams
- recruiters
- people managing multiple Google/Microsoft identities

### Secondary

- privacy-conscious users separating contexts
- power users with browser-specific workflows
- QA testers
- social media managers

---

## 4) Core User Stories

### Manual routing

As a user, when I click any web link, I want a popup showing my browsers so I can decide where it opens.

### Profile selection

As a user, when I click a browser's chevron, I want to see its profiles in a side panel so I can choose the correct account context.

### Automatic routing

As a user, I want to set domain/URL rules so that matching links bypass the popup and open directly in the right browser and profile.

### Incognito mode

As a user, I want the option to open any link in a private/incognito window without leaving the popup.

### Keyboard-driven workflow

As a user, I want to navigate the popup entirely with keyboard shortcuts for maximum speed.

### Default browser replacement

As a user, I want to set this app as my default browser so it works everywhere on macOS.

### Work-life separation

As a user, I want certain domains to consistently open in my work or personal profiles.

---

## 5) Product Goals

### Primary goals

- reduce wrong-profile link opens
- reduce context switching time
- make profile selection feel instant
- become the user's permanent default browser layer

### Success outcomes

- user chooses correct destination in under 1 second
- repeated domains become nearly zero-friction via rules
- users stop manually opening browsers first

---

## 6) Shipped Features (v1.1)

### Core

- Registers as default browser (http/https URL schemes)
- Intercepts all clicked links system-wide
- Floating popup chooser (NSPanel, non-activating, doesn't steal focus)
- Browser list with icons and number indices for keyboard reference
- Profile side panel via chevron hover
- Incognito/private mode toggle (Chromium --incognito, Firefox --private-window)

### Automation

- Domain/URL rules (domain, glob, regex matching) — auto-routes without popup
- URL rewriting rules (regex-based transformation before routing)

### Productivity

- Copy URL to clipboard from popup
- Full keyboard navigation (1-9 select browser, arrows navigate, Enter confirms, c copies, i toggles incognito, Escape dismisses)
- Link history log (last 500 entries, searchable)

### Settings and UX

- Tabbed settings window (General, Rules, Rewrite, History)
- First-launch onboarding with default browser setup
- Launch at login toggle (SMAppService)
- Menu bar icon with settings and quit
- Opens settings from Spotlight/Finder
- DMG distribution via GitHub Releases

---

## 7) UX Principles

### 1. Zero interruption

Popup floats above all windows without stealing focus.

### 2. Keyboard-first speed

Full keyboard navigation — number keys, arrows, Enter, shortcuts.

### 3. Memory over repetition

Domain/URL rules make frequent destinations automatic.

### 4. Reversible automation

Rules can be toggled, edited, or deleted in settings at any time.

### 5. Native macOS feel

NSPanel, vibrancy material, system icons — feels like a native macOS utility.

---

## 8) Key Screens / Surfaces

- Floating popup (browser list + profile side panel)
- Popup URL header (copy, incognito toggle, settings gear)
- Settings > General (about, launch at login, default browser status)
- Settings > Rules (add/edit/delete domain and URL pattern rules)
- Settings > Rewrite (add/edit/delete URL rewrite rules)
- Settings > History (searchable link log with clear)
- Onboarding window (first launch)
- Menu bar dropdown (settings, quit)

---

## 9) Differentiators

The strongest differentiation is:

> **profile-aware routing as the primary interaction, not a secondary setting**

This product optimizes for:

- identity context
- profile memory
- domain intent
- keyboard-driven selection
- URL automation (rules + rewriting)

---

## 10) Sustainability Model

This product is **source-available but proprietary** (not open source).

- Free for personal download and use
- No commercial use
- No redistribution
- No derivative works

See LICENSE for full terms.

---

## 11) Risks

### Product risks

- users may compare against existing browser choosers
- initial setup must be extremely smooth
- too much decision friction can reduce adoption

### UX risks

- popup latency kills trust
- too many visible profiles may overwhelm users

### Market risk

Need a clearly visible advantage over generic browser switchers.

That advantage is:

> **best-in-class profile routing speed + domain automation**

---

## 12) Product Positioning

**For professionals juggling multiple identities online, BrowserPicker is the fastest way to ensure every link opens in the right browser context.**

Unlike generic browser choosers, it is designed around **profile-level intent, automation, and speed**.

---

## 13) Success Metrics

- default browser setup completion rate
- successful first routed link
- % of links opened via rules (bypassing popup)
- average decision time in popup
- repeat weekly usage
