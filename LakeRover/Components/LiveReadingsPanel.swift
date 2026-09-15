import SwiftUI

/// "Data langsung" — the four readings during a sampling run (R7.3).
struct LiveReadingsPanel: View {
    var sampling: SamplingTelemetry?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data langsung").sectionTitle()
            ForEach(Parameter.charted) { parameter in
                VStack(alignment: .leading, spacing: 1) {
                    Text(parameter.shortLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(valueText(parameter))
                        .font(Theme.numberFont)
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func valueText(_ parameter: Parameter) -> String {
        guard let sampling, sampling.phase >= .sample else { return "—" }
        return parameter.format(sampling.value(for: parameter))
    }
}

/// Filled / target volume plus the estimate (R7.4).
struct FillProgress: View {
    var filledL: Double
    var targetL: Double
    var secondsRemaining: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Isipadu disampel").sectionTitle()
                Spacer()
                Text(String(format: "%.1f / %.1f L", filledL, targetL))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: min(filledL / max(targetL, 0.1), 1))
                .tint(Theme.accent)
            Text(estimateText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var estimateText: String {
        guard secondsRemaining > 1 else { return String(localized: "Pensampelan hampir selesai") }
        let minutes = Int((secondsRemaining / 60).rounded(.up))
        return "Anggaran selesai dalam \(minutes) min"
    }
}

/// Camera thumbnail on the Sampling screen — tapping opens the camera sheet.
struct CameraThumb: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kamera langsung").sectionTitle()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                    Image(systemName: "video.fill")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 84)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
