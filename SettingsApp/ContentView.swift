import SwiftUI

struct ContentView: View {
	@State private var settings = DockSettings()

	var body: some View {
		NavigationStack {
			List {
				ReflectionSettingsSection(settings: settings)
				IndicatorSettingsSection(settings: settings)
			}
			.listStyle(.sidebar)
			.toolbar {
				Button("Restart Dock", systemImage: "arrow.clockwise", action: settings.restartDock)
					.buttonStyle(.borderedProminent)
					.labelStyle(.titleAndIcon)

				Button("Restore defaults", systemImage: "arrow.uturn.backward", action: settings.restoreDefaults)
					.labelStyle(.titleAndIcon)
			}
			.monospaced()
		}
		.frame(minWidth: 620, minHeight: 620)
	}
}

#Preview {
	ContentView()
}
