// BrowserPicker — Copyright (c) 2026 Shobhit. All rights reserved.
// Licensed under a proprietary license. See LICENSE file for details.

import Combine
import Foundation

enum PopupKeyAction: Equatable {
    case selectBrowser(Int)
    case confirm
    case toggleIncognito
    case copyURL
    case moveUp
    case moveDown
    case expandProfiles
    case collapseProfiles
}

class PopupKeyboardState: ObservableObject {
    @Published var lastAction: PopupKeyAction?

    func send(_ action: PopupKeyAction) {
        lastAction = action
    }
}
