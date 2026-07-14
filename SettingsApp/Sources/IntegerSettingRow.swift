import SwiftUI

struct IntegerSettingRow: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        LabeledContent(title) {
            Stepper(value: $value, in: range) {
                Text(value, format: .number)
                    .monospacedDigit()
            }
            .accessibilityLabel(Text(title))
        }
    }
}
