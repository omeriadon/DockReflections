import Foundation
import Testing
@testable import DockReflectionsSettings

@MainActor
struct DockSettingsTests {
    @Test
    func readsFallbacksAndPersistsChanges() {
        let suiteName = "com.omeriadon.DockReflectionsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = DockSettings(defaults: defaults)
        #expect(settings.reflectionBlurRadius == DockSettingDefaults.reflectionBlurRadius)

        settings.reflectionBlurRadius = 7
        settings.indicatorGlowLayers = 9

        #expect(defaults.double(forKey: DockPreferenceKey.reflectionBlurRadius.rawValue) == 7)
        #expect(defaults.integer(forKey: DockPreferenceKey.indicatorGlowLayers.rawValue) == 9)
    }
}
