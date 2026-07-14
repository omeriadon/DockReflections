import Foundation
import Observation

@Observable
@MainActor
final class DockSettings {
	static let preferenceDomain = "com.omeriadon.DockReflections"

	@ObservationIgnored private let defaults: UserDefaults

	var reflectionEnabled: Bool {
		didSet { write(reflectionEnabled, for: .enabled) }
	}

	var reflectionScale: Double {
		didSet { write(reflectionScale, for: .reflectionScale) }
	}

	var reflectionYOffset: Double {
		didSet { write(reflectionYOffset, for: .reflectionYOffset) }
	}

	var reflectionOpacity: Double {
		didSet { write(reflectionOpacity, for: .reflectionOpacity) }
	}

	var reflectionBlurRadius: Double {
		didSet { write(reflectionBlurRadius, for: .reflectionBlurRadius) }
	}

	var reflectFolders: Bool {
		didSet { write(reflectFolders, for: .reflectFolders) }
	}

	var reflectTrash: Bool {
		didSet { write(reflectTrash, for: .reflectTrash) }
	}

	var indicatorsEnabled: Bool {
		didSet { write(indicatorsEnabled, for: .indicatorsEnabled) }
	}

	var indicatorWidth: Double {
		didSet { write(indicatorWidth, for: .indicatorWidth) }
	}

	var indicatorHeight: Double {
		didSet { write(indicatorHeight, for: .indicatorHeight) }
	}

	var indicatorCornerRadius: Double {
		didSet { write(indicatorCornerRadius, for: .indicatorCornerRadius) }
	}

	var indicatorYOffset: Double {
		didSet { write(indicatorYOffset, for: .indicatorYOffset) }
	}

	var indicatorOpacity: Double {
		didSet { write(indicatorOpacity, for: .indicatorOpacity) }
	}

	var indicatorBlurRadius: Double {
		didSet { write(indicatorBlurRadius, for: .indicatorBlurRadius) }
	}

	var indicatorTransitionBlurRadius: Double {
		didSet { write(indicatorTransitionBlurRadius, for: .indicatorTransitionBlurRadius) }
	}

	var indicatorGlowOpacity: Double {
		didSet { write(indicatorGlowOpacity, for: .indicatorGlowOpacity) }
	}

	var indicatorGlowLayers: Int {
		didSet { write(indicatorGlowLayers, for: .indicatorGlowLayers) }
	}

	var indicatorEntryDuration: Double {
		didSet { write(indicatorEntryDuration, for: .indicatorEntryDuration) }
	}

	var indicatorExitDuration: Double {
		didSet { write(indicatorExitDuration, for: .indicatorExitDuration) }
	}

	private(set) var restartStatus: String?

	convenience init() {
		let defaults = UserDefaults(suiteName: Self.preferenceDomain) ?? .standard
		self.init(defaults: defaults)
	}

	init(defaults: UserDefaults) {
		self.defaults = defaults

		reflectionEnabled = Self.bool(.enabled, from: defaults, fallback: DockSettingDefaults.reflectionEnabled)
		reflectionScale = Self.double(.reflectionScale, from: defaults, fallback: DockSettingDefaults.reflectionScale)
		reflectionYOffset = Self.double(.reflectionYOffset, from: defaults, fallback: DockSettingDefaults.reflectionYOffset)
		reflectionOpacity = Self.double(.reflectionOpacity, from: defaults, fallback: DockSettingDefaults.reflectionOpacity)
		reflectionBlurRadius = Self.double(.reflectionBlurRadius, from: defaults, fallback: DockSettingDefaults.reflectionBlurRadius)
		reflectFolders = Self.bool(.reflectFolders, from: defaults, fallback: DockSettingDefaults.reflectFolders)
		reflectTrash = Self.bool(.reflectTrash, from: defaults, fallback: DockSettingDefaults.reflectTrash)

		indicatorsEnabled = Self.bool(.indicatorsEnabled, from: defaults, fallback: DockSettingDefaults.indicatorsEnabled)
		indicatorWidth = Self.double(.indicatorWidth, from: defaults, fallback: DockSettingDefaults.indicatorWidth)
		indicatorHeight = Self.double(.indicatorHeight, from: defaults, fallback: DockSettingDefaults.indicatorHeight)
		indicatorCornerRadius = Self.double(.indicatorCornerRadius, from: defaults, fallback: DockSettingDefaults.indicatorCornerRadius)
		indicatorYOffset = Self.double(.indicatorYOffset, from: defaults, fallback: DockSettingDefaults.indicatorYOffset)
		indicatorOpacity = Self.double(.indicatorOpacity, from: defaults, fallback: DockSettingDefaults.indicatorOpacity)
		indicatorBlurRadius = Self.double(.indicatorBlurRadius, from: defaults, fallback: DockSettingDefaults.indicatorBlurRadius)
		indicatorTransitionBlurRadius = Self.double(.indicatorTransitionBlurRadius, from: defaults, fallback: DockSettingDefaults.indicatorTransitionBlurRadius)
		indicatorGlowOpacity = Self.double(.indicatorGlowOpacity, from: defaults, fallback: DockSettingDefaults.indicatorGlowOpacity)
		indicatorGlowLayers = Self.integer(.indicatorGlowLayers, from: defaults, fallback: DockSettingDefaults.indicatorGlowLayers)
		indicatorEntryDuration = Self.double(.indicatorEntryDuration, from: defaults, fallback: DockSettingDefaults.indicatorEntryDuration)
		indicatorExitDuration = Self.double(.indicatorExitDuration, from: defaults, fallback: DockSettingDefaults.indicatorExitDuration)
	}

	func restartDock() {
		defaults.synchronize()

		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/killall")
		process.arguments = ["Dock"]

		do {
			try process.run()
			process.waitUntilExit()
			restartStatus = process.terminationStatus == 0
				? "Dock restarted with the current settings."
				: "Dock could not be restarted. killall exited with status \(process.terminationStatus)."
		} catch {
			restartStatus = "Dock could not be restarted: \(error.localizedDescription)"
		}
	}

	func restoreDefaults() {
		for key in DockPreferenceKey.allCases {
			defaults.removeObject(forKey: key.rawValue)
		}

		reflectionEnabled = DockSettingDefaults.reflectionEnabled
		reflectionScale = DockSettingDefaults.reflectionScale
		reflectionYOffset = DockSettingDefaults.reflectionYOffset
		reflectionOpacity = DockSettingDefaults.reflectionOpacity
		reflectionBlurRadius = DockSettingDefaults.reflectionBlurRadius
		reflectFolders = DockSettingDefaults.reflectFolders
		reflectTrash = DockSettingDefaults.reflectTrash
		indicatorsEnabled = DockSettingDefaults.indicatorsEnabled
		indicatorWidth = DockSettingDefaults.indicatorWidth
		indicatorHeight = DockSettingDefaults.indicatorHeight
		indicatorCornerRadius = DockSettingDefaults.indicatorCornerRadius
		indicatorYOffset = DockSettingDefaults.indicatorYOffset
		indicatorOpacity = DockSettingDefaults.indicatorOpacity
		indicatorBlurRadius = DockSettingDefaults.indicatorBlurRadius
		indicatorTransitionBlurRadius = DockSettingDefaults.indicatorTransitionBlurRadius
		indicatorGlowOpacity = DockSettingDefaults.indicatorGlowOpacity
		indicatorGlowLayers = DockSettingDefaults.indicatorGlowLayers
		indicatorEntryDuration = DockSettingDefaults.indicatorEntryDuration
		indicatorExitDuration = DockSettingDefaults.indicatorExitDuration
		restartStatus = "Default settings restored. Restart Dock to apply them."
	}

	private func write(_ value: Any, for key: DockPreferenceKey) {
		defaults.set(value, forKey: key.rawValue)
	}

	private static func bool(_ key: DockPreferenceKey, from defaults: UserDefaults, fallback: Bool) -> Bool {
		guard defaults.object(forKey: key.rawValue) != nil else { return fallback }
		return defaults.bool(forKey: key.rawValue)
	}

	private static func double(_ key: DockPreferenceKey, from defaults: UserDefaults, fallback: Double) -> Double {
		guard defaults.object(forKey: key.rawValue) != nil else { return fallback }
		return defaults.double(forKey: key.rawValue)
	}

	private static func integer(_ key: DockPreferenceKey, from defaults: UserDefaults, fallback: Int) -> Int {
		guard defaults.object(forKey: key.rawValue) != nil else { return fallback }
		return defaults.integer(forKey: key.rawValue)
	}
}
