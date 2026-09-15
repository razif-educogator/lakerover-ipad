import SwiftUI

/// Non-AR fallback (R5.6). Used on the Simulator, where there is no AR camera.
/// It speaks exactly the same notification contract as the Reality Composer scene:
/// tapping a callout posts the component's `NotifyAction` identifier.
struct RoverDiagramView: View {
    var model: RoverModelViewModel

    private struct Callout {
        var component: RoverComponent
        var label: CGPoint
        var hotspot: CGPoint
    }

    private let callouts: [Callout] = [
        Callout(component: .antenaGPS, label: CGPoint(x: 0.29, y: 0.12), hotspot: CGPoint(x: 0.50, y: 0.30)),
        Callout(component: .kamera360, label: CGPoint(x: 0.79, y: 0.22), hotspot: CGPoint(x: 0.56, y: 0.45)),
        Callout(component: .panelSolar, label: CGPoint(x: 0.19, y: 0.44), hotspot: CGPoint(x: 0.43, y: 0.50)),
        Callout(component: .pendorong, label: CGPoint(x: 0.81, y: 0.68), hotspot: CGPoint(x: 0.63, y: 0.63)),
        Callout(component: .pensampel, label: CGPoint(x: 0.27, y: 0.85), hotspot: CGPoint(x: 0.46, y: 0.66))
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.06), Theme.accent.opacity(0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                ForEach(0..<3, id: \.self) { i in
                    Wave(phase: Double(i) * 0.7)
                        .stroke(Theme.accent.opacity(0.35 - Double(i) * 0.08), lineWidth: 2)
                        .frame(height: 16)
                        .position(x: w / 2, y: h * (0.74 + Double(i) * 0.08))
                }

                RoverGlyph()
                    .frame(width: w * 0.34, height: h * 0.3)
                    .scaleEffect(model.realScale ? 1.3 : 1.0)
                    .animation(.spring(duration: 0.4), value: model.realScale)
                    .position(x: w * 0.5, y: h * 0.52)
                    .opacity(model.isPlayingSampling ? 0.9 : 1)

                ForEach(callouts, id: \.component) { callout in
                    let visible = model.group.components.contains(callout.component)
                    let labelPoint = CGPoint(x: callout.label.x * w, y: callout.label.y * h)
                    let hotPoint = CGPoint(x: callout.hotspot.x * w, y: callout.hotspot.y * h)

                    Path { path in
                        path.move(to: labelPoint)
                        path.addLine(to: hotPoint)
                    }
                    .stroke(Theme.accent.opacity(visible ? 0.55 : 0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    Circle()
                        .fill(Theme.accent.opacity(visible ? 1 : 0.2))
                        .frame(width: 9, height: 9)
                        .position(hotPoint)

                    Button {
                        model.tap(callout.component)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: callout.component.symbol)
                            Text(callout.component.title)
                        }
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            model.selected == callout.component ? Theme.accent : Color(.systemBackground),
                            in: Capsule()
                        )
                        .foregroundStyle(model.selected == callout.component ? Color.white : Color.primary)
                        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .opacity(visible ? 1 : 0.25)
                    .disabled(!visible)
                    .position(labelPoint)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: model.group)
        }
    }
}
