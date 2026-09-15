import SwiftUI

/// The four-column sensor readout on the sample detail pane.
struct SensorTable: View {
    var turbidityNTU: Double?
    var temperatureC: Double?
    var pH: Double?
    var dissolvedOxygenMgL: Double?

    private var columns: [(String, Double?)] {
        [("NTU", turbidityNTU), ("°C", temperatureC), ("pH", pH), ("DO", dissolvedOxygenMgL)]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                VStack(spacing: 4) {
                    Text(column.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(column.1.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(alignment: .trailing) {
                    if index < columns.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
