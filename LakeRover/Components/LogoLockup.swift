import SwiftUI

struct LogoLockup: View {
    var compact = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Text("Lake").foregroundStyle(.primary)
                Text("Rover").foregroundStyle(Theme.accent)
            }
            .font(.system(size: compact ? 30 : 46, weight: .bold, design: .rounded))

            Text("Explore · Measure · Protect")
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.secondary)
                .tracking(1.5)
        }
    }
}

/// The lake illustration on the Splash screen: a rover silhouette on three waves.
struct LakeIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.10), Theme.accent.opacity(0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // Far hills
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.52))
                    p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.26))
                    p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.52))
                    p.closeSubpath()
                    p.move(to: CGPoint(x: w * 0.34, y: h * 0.52))
                    p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.18))
                    p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.52))
                    p.closeSubpath()
                }
                .fill(Theme.accent.opacity(0.22))

                // Rover
                RoverGlyph()
                    .frame(width: w * 0.26, height: h * 0.2)
                    .position(x: w * 0.5, y: h * 0.53)

                // Waves
                ForEach(0..<3, id: \.self) { i in
                    Wave(phase: Double(i) * 0.6)
                        .stroke(Theme.accent.opacity(0.55 - Double(i) * 0.13), lineWidth: 2.5)
                        .frame(height: 18)
                        .position(x: w / 2, y: h * (0.66 + Double(i) * 0.11))
                }
            }
        }
    }
}

struct RoverGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Hull
                Path { p in
                    p.move(to: CGPoint(x: w * 0.08, y: h * 0.55))
                    p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.55))
                    p.addLine(to: CGPoint(x: w * 0.78, y: h))
                    p.addLine(to: CGPoint(x: w * 0.22, y: h))
                    p.closeSubpath()
                }
                .fill(Theme.accent)

                // Solar deck
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent.opacity(0.7))
                    .frame(width: w * 0.55, height: h * 0.18)
                    .position(x: w * 0.5, y: h * 0.4)

                // Mast
                Rectangle()
                    .fill(Theme.accent.opacity(0.8))
                    .frame(width: 2, height: h * 0.32)
                    .position(x: w * 0.5, y: h * 0.18)
            }
        }
    }
}

struct Wave: Shape {
    var phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY))
        let steps = 60
        for i in 0...steps {
            let x = rect.minX + rect.width * Double(i) / Double(steps)
            let y = midY + sin(Double(i) / Double(steps) * 2 * .pi * 1.6 + phase) * rect.height * 0.4
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
