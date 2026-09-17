import SwiftUI

/// Satelit / Kedalaman / Kekeruhan (R3.5). Sits in the Live map's left column, in the same card
/// chrome as `RoverStatusPanel` and `WeatherCard` so the three read as one tidy stack.
struct LayerChips: View {
    @Binding var layer: MapLayer
    /// `.vertical` in portrait. Landscape puts the three chips in one row, which drops the card
    /// from about 105 pt to ~60 pt and hands that height to the station card below.
    var axis: Axis = .vertical

    private let options: [MapLayer] = [.satellite, .depth, .turbidity]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Lapisan peta")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.bottom, 4)

            if axis == .vertical {
                VStack(spacing: 6) { chips }
            } else {
                HStack(spacing: 6) { chips }
            }
        }
        // Same 190 pt content width + 12 pt padding as the cards above, so the column aligns.
        .frame(width: 190, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder private var chips: some View {
        ForEach(options, id: \.self) { option in
            Button {
                layer = layer == option ? .standard : option
            } label: {
                Text(option.label)
                    .font((axis == .vertical ? Font.caption : Font.caption2)
                        .weight(layer == option ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    // Chips share the card's width: full width when stacked, an equal third
                    // each when in a row.
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        layer == option
                            ? AnyShapeStyle(Theme.accent)
                            : AnyShapeStyle(Color(.tertiarySystemFill)),
                        in: Capsule()
                    )
                    .foregroundStyle(layer == option ? Color.white : Color.primary)
            }
            .buttonStyle(.plain)
        }
    }
}
