import SwiftUI

@main
struct BrowserPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserPicker", systemImage: "globe") {
            MenuBarView()
        }
    }
}
