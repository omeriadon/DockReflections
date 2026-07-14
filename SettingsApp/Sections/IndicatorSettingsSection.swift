import SwiftUI

struct IndicatorSettingsSection: View {
	@Bindable var settings: DockSettings

	var body: some View {
		Section(
			"Running app indicators"
		) {
			Toggle(
				"Enable custom indicators",
				isOn: $settings.indicatorsEnabled
			)

			NumericSettingRow(
				title: "Width",
				value: $settings.indicatorWidth,
				range: 1 ... 40,
				step: 1
			)
			NumericSettingRow(
				title: "Height",
				value: $settings.indicatorHeight,
				range: 1 ... 20,
				step: 1
			)
			NumericSettingRow(
				title: "Corner radius",
				value: $settings.indicatorCornerRadius,
				range: 0 ... 10,
				step: 0.5
			)
			NumericSettingRow(
				title: "Vertical offset",
				value: $settings.indicatorYOffset,
				range: -30 ... 30,
				step: 1
			)
			NumericSettingRow(
				title: "Opacity",
				value: $settings.indicatorOpacity,
				range: 0 ... 1,
				step: 0.05
			)
			NumericSettingRow(
				title: "Glow blur radius",
				value: $settings.indicatorBlurRadius,
				range: 0 ... 50,
				step: 1
			)
			NumericSettingRow(
				title: "Transition blur radius",
				value: $settings.indicatorTransitionBlurRadius,
				range: 0 ... 50,
				step: 1
			)
			NumericSettingRow(
				title: "Glow opacity",
				value: $settings.indicatorGlowOpacity,
				range: 0 ... 1,
				step: 0.1
			)
			IntegerSettingRow(
				title: "Glow layers",
				value: $settings.indicatorGlowLayers,
				range: 1 ... 12
			)
			NumericSettingRow(
				title: "Entry duration",
				value: $settings.indicatorEntryDuration,
				range: 0.05 ... 2,
				step: 0.05
			)
			NumericSettingRow(
				title: "Exit duration",
				value: $settings.indicatorExitDuration,
				range: 0.05 ... 2,
				step: 0.05
			)
		}
	}
}
