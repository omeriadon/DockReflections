import SwiftUI

struct ReflectionSettingsSection: View {
    @Bindable var settings: DockSettings

    var body: some View {
        Section("Reflections") {
            Toggle("Enable reflections", isOn: $settings.reflectionEnabled)

            NumericSettingRow(
                title: "Scale",
                value: $settings.reflectionScale,
                range: 0.35...1.0,
                step: 0.01
            )
            NumericSettingRow(
                title: "Vertical offset",
                value: $settings.reflectionYOffset,
                range: -40...40,
                step: 1
            )
            NumericSettingRow(
                title: "Opacity",
                value: $settings.reflectionOpacity,
                range: 0...1,
                step: 0.01
            )
            NumericSettingRow(
                title: "Blur radius",
                value: $settings.reflectionBlurRadius,
                range: 0...40,
                step: 1
            )

            Toggle("Reflect folders", isOn: $settings.reflectFolders)
            Toggle("Reflect Trash", isOn: $settings.reflectTrash)
        }
    }
}
