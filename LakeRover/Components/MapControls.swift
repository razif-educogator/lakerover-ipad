import SwiftUI

/// Recentre, camera and the always-visible emergency stop (R3.6, R3.7).
///
/// All three are built from the same `roundControl`: a fixed-diameter circle holding only the
/// icon, with the caption underneath. Putting the label inside the circle used to overflow it.
struct MapControls: View {
    var stopped: Bool
    var onRecentre: () -> Void
    var onCamera: () -> Void
    var onStop: () -> Void

    /// Shared metrics so the three controls line up on one column.
    private static let diameter: CGFloat = 52
    private static let slotWidth: CGFloat = 72

    var body: some View {
        VStack(spacing: 14) {
            roundControl(
                symbol: "scope",
                caption: "Pusat",
                fill: AnyShapeStyle(Material.regular),
                foreground: .primary,
                bordered: true,
                action: onRecentre
            )
            .accessibilityLabel("Pusatkan peta pada misi")

            roundControl(
                symbol: "video.fill",
                caption: "Kamera",
                fill: AnyShapeStyle(Material.regular),
                foreground: .primary,
                bordered: true,
                action: onCamera
            )
            .accessibilityLabel("Kamera langsung")

            roundControl(
                symbol: stopped ? "play.fill" : "stop.fill",
                caption: stopped ? "Sambung" : "Berhenti",
                fill: AnyShapeStyle(stopped ? Theme.success : Theme.critical),
                foreground: .white,
                bordered: false,
                action: onStop
            )
            .accessibilityLabel(stopped ? "Sambung semula misi" : "Berhenti kecemasan")
        }
    }

    private func roundControl(
        symbol: String,
        caption: LocalizedStringKey,
        fill: AnyShapeStyle,
        foreground: Color,
        bordered: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(foreground)
                    .frame(width: Self.diameter, height: Self.diameter)
                    .background(fill, in: Circle())
                    .overlay {
                        if bordered {
                            Circle().strokeBorder(Theme.hairline, lineWidth: 1)
                        }
                    }
                    .shadow(radius: 4, y: 2)

                Text(caption)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }
            .frame(width: Self.slotWidth)
        }
        .buttonStyle(.plain)
    }
}
