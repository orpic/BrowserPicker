# PRD — BrowserPicker for macOS

## 1) Product Summary

A macOS default-browser utility that intercepts every clicked web link and lets the user choose **which browser and which browser profile** should open it.

The product’s core value is **intentional link routing without browser friction**.

Instead of forcing users to manually switch browsers or profiles, the app presents a lightweight popup showing available browsers, then expands into available profiles on hover.

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
- not optimized for fast keyboard + hover workflows

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

As a user, when I hover a browser, I want to instantly see its profiles so I can choose the correct account context.

### Fast repeat behavior

As a user, I want the app to remember my common choices so repeated domains become one-click decisions.

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
- become the user’s permanent default browser layer

### Success outcomes

- user chooses correct destination in under 1 second
- repeated domains become nearly zero-friction
- users stop manually opening browsers first

---

## 6) MVP Scope

### Included in MVP

- app can be set as default browser
- intercepts all clicked links
- lightweight popup chooser
- browser list
- hover to reveal profiles
- click profile to open link
- optional “always open this domain in this profile” rule
- simple settings screen
- launch on startup

This keeps MVP focused on **speed + reliability of routing decisions**.

---

## 7) UX Principles

### 1. Zero interruption

Popup should feel lighter than a system menu.

### 2. Hover-first speed

Profile reveal should require no extra click.

### 3. Memory over repetition

Frequent choices should naturally become defaults.

### 4. Reversible automation

Automatic domain rules must always be easy to override.

### 5. Native macOS feel

The interaction should feel like Spotlight / Raycast / native menus.

---

## 8) Key Screens / Surfaces

- link routing popup
- browser hover profile panel
- settings window
- domain rules manager
- recent choices list
- onboarding flow for default browser setup

---

## 9) Differentiators

The strongest differentiation is:

> **profile-aware routing as the primary interaction, not a secondary setting**

Most competing tools optimize for browser choice.

This product optimizes for:

- identity context
- profile memory
- domain intent
- fast hover selection

That is a much stronger workflow advantage.

---

## 10) Sustainability Model

This product is intended to remain **fully open source and unrestricted**.

There will be:

- no paywalls
- no feature gating
- no Pro plan
- no domain-rule limits
- no premium restrictions

Users can optionally support development through:

- GitHub Sponsors
- Buy Me a Coffee
- one-time lifetime support contribution
- voluntary donations

The product philosophy is:

> **core utility should remain free, durable, and community-owned**

Any financial support exists only to sustain maintenance, roadmap work, and long-term reliability.

---

## 11) Risks

### Product risks

- users may compare against existing browser choosers
- initial setup must be extremely smooth
- too much decision friction can reduce adoption

### UX risks

- popup latency kills trust
- too many visible profiles may overwhelm users
- hover behavior must be predictable

### Market risk

Need a clearly visible advantage over generic browser switchers.

That advantage should remain:

> **best-in-class profile routing speed**

---

---

## 13) Product Positioning

**For professionals juggling multiple identities online, BrowserPicker is the fastest way to ensure every link opens in the right browser context.**

Unlike generic browser choosers, it is designed around **profile-level intent, memory, and speed**.

---

## 14) MVP Success Metrics

- default browser setup completion rate
- successful first routed link
- % of links opened via remembered rules
- average decision time
- repeat weekly usage
- voluntary supporter conversion rate

---

