import SwiftUI

struct ProgressHeader: View {
    var completed: Int
    var total: Int
    var estimatedFinish: Date?
    var remainingDistanceM: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completed) / \(total) stesen selesai")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            ProgressView(value: fraction)
                .tint(Theme.accent)
            Text(metaLine)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var fraction: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    private var metaLine: String {
        let eta = estimatedFinish?.formatted(date: .omitted, time: .shortened) ?? "—"
        let distance = remainingDistanceM >= 1000
            ? String(format: "%.1f km", remainingDistanceM / 1000)
            : String(format: "%.0f m", remainingDistanceM)
        return "Anggaran siap \(eta) · Baki jarak \(distance)"
    }
}
