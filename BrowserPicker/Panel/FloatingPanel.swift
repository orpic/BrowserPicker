// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    var keyboardState: PopupKeyboardState?

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.contentView = NSHostingView(rootView: contentView)
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            NotificationCenter.default.post(name: .dismissPopup, object: nil)
        case 126: // Up arrow
            keyboardState?.send(.moveUp)
        case 125: // Down arrow
            keyboardState?.send(.moveDown)
        case 124: // Right arrow
            keyboardState?.send(.expandProfiles)
        case 123: // Left arrow
            keyboardState?.send(.collapseProfiles)
        case 36, 76: // Return / Enter
            keyboardState?.send(.confirm)
        default:
            if let chars = event.charactersIgnoringModifiers, chars.count == 1 {
                let ch = chars.first!
                switch ch {
                case "1"..."9":
                    let index = Int(String(ch))! - 1
                    keyboardState?.send(.selectBrowser(index))
                case "c":
                    keyboardState?.send(.copyURL)
                case "i":
                    keyboardState?.send(.toggleIncognito)
                default:
                    super.keyDown(with: event)
                }
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

extension Notification.Name {
    static let dismissPopup = Notification.Name("BrowserPicker.dismissPopup")
}
