// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import AppKit
import SwiftUI

final class FloatingPanelController {
    private var panel: FloatingPanel?
    private var clickMonitor: Any?
    private var dismissObserver: Any?

    var onProfileSelected: ((Browser, BrowserProfile?) -> Void)?

    func show(url: URL, browsers: [Browser], profiles: [String: [BrowserProfile]]) {
        dismiss()

        let popupView = RouterPopupView(
            url: url,
            browsers: browsers,
            profiles: profiles,
            onProfileSelected: { [weak self] browser, profile in
                self?.onProfileSelected?(browser, profile)
                self?.dismiss()
            }
        )

        let panel = FloatingPanel(contentView: popupView)
        self.panel = panel

        positionNearMouse(panel)
        panel.makeKeyAndOrderFront(nil)

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

    private func positionNearMouse(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation

        guard let screen = NSScreen.screens.first(where: {
            $0.frame.contains(mouseLocation)
        }) ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        var x = mouseLocation.x - panelSize.width / 2
        var y = mouseLocation.y - panelSize.height / 2

        x = max(screenFrame.minX + 8, min(x, screenFrame.maxX - panelSize.width - 8))
        y = max(screenFrame.minY + 8, min(y, screenFrame.maxY - panelSize.height - 8))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
