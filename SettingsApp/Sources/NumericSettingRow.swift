import SwiftUI

struct NumericSettingRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        LabeledContent(title) {
            HStack {
                Slider(value: $value, in: range, step: step)
                    .accessibilityLabel(Text(title))

                TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
            }
            .frame(maxWidth: 360)
        }
    }
}
