import SwiftUI

struct DockActionsSection: View {
    let settings: DockSettings

    var body: some View {
        Section("Apply") {
            HStack {
                Button("Restart Dock", systemImage: "arrow.clockwise", action: settings.restartDock)
                    .buttonStyle(.borderedProminent)

                Button("Restore defaults", systemImage: "arrow.uturn.backward", action: settings.restoreDefaults)
            }

            if let restartStatus = settings.restartStatus {
                Label(restartStatus, systemImage: "info.circle")
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}
