import SwiftUI

struct ParameterChecklist: View {
    @Binding var selection: Set<Parameter>

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Parameter.allCases) { parameter in
                Button {
                    if selection.contains(parameter) {
                        selection.remove(parameter)
                    } else {
                        selection.insert(parameter)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selection.contains(parameter) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(selection.contains(parameter) ? Theme.accent : .secondary)
                        Text(parameter.label)
                        if parameter.isLabAnalysis {
                            // No sensor reads this in the field, so say so up front.
                            StatusPill(text: "analisis makmal", symbol: "flask.fill", tint: Theme.warning)
                        }
                        Spacer()
                        Text(parameter.unit)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                if parameter != Parameter.allCases.last {
                    Divider()
                }
            }
        }
    }
}
