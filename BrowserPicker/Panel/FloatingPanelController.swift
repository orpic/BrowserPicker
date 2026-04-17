// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit
import SwiftUI

final class FloatingPanelController {
    private var panel: FloatingPanel?
    private var clickMonitor: Any?
    private var dismissObserver: Any?

    var onProfileSelected: ((Browser, BrowserProfile?, Bool) -> Void)?

    func show(url: URL, browsers: [Browser], profiles: [String: [BrowserProfile]]) {
        dismiss()

        let keyboardState = PopupKeyboardState()
        let popupView = RouterPopupView(
            url: url,
            browsers: browsers,
            profiles: profiles,
            keyboardState: keyboardState,
            onProfileSelected: { [weak self] browser, profile, incognito in
                self?.onProfileSelected?(browser, profile, incognito)
                self?.dismiss()
            }
        )

        let panel = FloatingPanel(contentView: popupView)
        panel.keyboardState = keyboardState
        self.panel = panel

        positionNearMouse(panel)
        panel.makeKeyAndOrderFront(nil)
        panel.makeKey()

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.dismiss()
        }

        dismissObserver = NotificationCenter.default.addObserver(
            forName: .dismissPopup,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil

        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }

        if let observer = dismissObserver {
            NotificationCenter.default.removeObserver(observer)
            dismissObserver = nil
        }
    }

    private static let expandedWidth: CGFloat = 280 + 1 + 240
    private static let panelWidth: CGFloat = 280

    private func positionNearMouse(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation

        guard let screen = NSScreen.screens.first(where: {
            $0.frame.contains(mouseLocation)
        }) ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelHeight = panel.frame.size.height

        var x = mouseLocation.x - Self.panelWidth / 2
        var y = mouseLocation.y - panelHeight / 2

        let maxX = screenFrame.maxX - Self.expandedWidth - 8
        x = max(screenFrame.minX + 8, min(x, maxX))
        y = max(screenFrame.minY + 8, min(y, screenFrame.maxY - panelHeight - 8))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
