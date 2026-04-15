import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .imageScale(.large)
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("BrowserPicker")
                .font(.title)

            Text("v1.0")
                .foregroundStyle(.secondary)

            Divider()

            Text("Settings will be added here.")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    SettingsView()
}
