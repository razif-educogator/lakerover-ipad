import SwiftUI

/// Tiba · Daftar · Sampel · Tag · Simpan · Gerak.
/// Shared by the Sampling screen and the AR model demo so both tell the same story.
struct StepBar: View {
    var current: SamplingPhase?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(SamplingPhase.allCases.enumerated()), id: \.element) { index, phase in
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(fill(for: phase))
                            .frame(width: 26, height: 26)
                        if let current, phase < current {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(phase == current ? .white : .secondary)
                        }
                    }
                    Text(phase.label)
                        .font(.caption2.weight(phase == current ? .semibold : .regular))
                        .foregroundStyle(phase == current ? Theme.accent : .secondary)
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) {
                    if index < SamplingPhase.allCases.count - 1 {
                        Rectangle()
                            .fill(connectorColor(after: phase))
                            .frame(height: 2)
                            .padding(.leading, 40)
                            .offset(y: 12)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: current)
    }

    private func fill(for phase: SamplingPhase) -> Color {
        guard let current else { return Color(.tertiarySystemFill) }
        if phase < current { return Theme.success }
        if phase == current { return Theme.accent }
        return Color(.tertiarySystemFill)
    }

    private func connectorColor(after phase: SamplingPhase) -> Color {
        guard let current, phase < current else { return Theme.hairline }
        return Theme.success
    }
}
