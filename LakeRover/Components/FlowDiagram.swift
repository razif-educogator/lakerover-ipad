import SwiftUI

/// Pam → Kartrij → Botol, animated while the pump runs (R7.2).
struct FlowDiagram: View {
    var active: Bool
    var fillFraction: Double

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 0) {
            stage(title: "Pam", symbol: "wind") {
                Image(systemName: "fan.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .rotationEffect(.degrees(pulse && active ? 360 : 0))
                    .animation(active ? .linear(duration: 1.4).repeatForever(autoreverses: false) : .default, value: pulse)
            }

            arrow

            stage(title: "Kartrij", symbol: "square.stack.3d.up") {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Theme.accent, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent.opacity(active ? 0.25 : 0.08))
                    )
                    .frame(width: 26, height: 34)
            }

            arrow

            stage(title: "Botol", symbol: "flask") {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Theme.accent, lineWidth: 2)
                        .frame(width: 24, height: 38)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accent.opacity(0.6))
                        .frame(width: 20, height: max(2, 34 * fillFraction))
                        .padding(.bottom, 2)
                        .animation(.easeInOut(duration: 0.4), value: fillFraction)
                }
            }
        }
        .frame(height: 78)
        .onAppear { pulse = true }
    }

    private func stage(title: String, symbol: String, @ViewBuilder glyph: () -> some View) -> some View {
        VStack(spacing: 6) {
            glyph()
                .frame(height: 40)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.caption)
            .foregroundStyle(active ? Theme.accent : Color(.tertiaryLabel))
            .offset(y: -6)
    }
}
