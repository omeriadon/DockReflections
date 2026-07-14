import SwiftUI

struct ContentView: View {
    @State private var settings = DockSettings()

    var body: some View {
        Form {
            ReflectionSettingsSection(settings: settings)
            IndicatorSettingsSection(settings: settings)
            DockActionsSection(settings: settings)
        }
        .formStyle(.grouped)
        .navigationTitle("Dock Reflections")
        .frame(minWidth: 620, minHeight: 620)
    }
}

#Preview {
    ContentView()
}
