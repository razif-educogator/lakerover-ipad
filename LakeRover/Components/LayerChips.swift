import SwiftUI

/// Satelit / Kedalaman / Kekeruhan (R3.5). Vertical stack, top-right of the Live map.
struct LayerChips: View {
    @Binding var layer: MapLayer

    private let options: [MapLayer] = [.satellite, .depth, .turbidity]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                Button {
                    layer = layer == option ? .standard : option
                } label: {
                    Text(option.label)
                        .font(.caption.weight(layer == option ? .semibold : .regular))
                        .frame(width: 104)
                        .padding(.vertical, 7)
                        .background(
                            layer == option
                                ? AnyShapeStyle(Color.black.opacity(0.82))
                                : AnyShapeStyle(Material.regular),
                            in: Capsule()
                        )
                        .foregroundStyle(layer == option ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
