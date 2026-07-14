import SwiftUI

struct IntegerSettingRow: View {
	let title: LocalizedStringKey
	@Binding var value: Int
	let range: ClosedRange<Int>

	var body: some View {
		HStack {
			Text(title)

			Spacer()

			Stepper(value: $value, in: range) {
				Text(value, format: .number)
					.monospacedDigit()
			}
			.accessibilityLabel(Text(title))
			.frame(width: 40)
		}
		.frame(maxWidth: 360)
	}
}
