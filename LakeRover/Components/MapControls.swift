import SwiftUI

/// Recentre, camera and the always-visible emergency stop (R3.6, R3.7).
struct MapControls: View {
    var stopped: Bool
    var onRecentre: () -> Void
    var onCamera: () -> Void
    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            circleButton(symbol: "scope", action: onRecentre)
                .accessibilityLabel("Pusatkan pada rover")
            circleButton(symbol: "video.fill", action: onCamera)
                .accessibilityLabel("Kamera langsung")

            Button(action: onStop) {
                VStack(spacing: 2) {
                    Image(systemName: stopped ? "play.fill" : "stop.fill")
                        .font(.title3.weight(.bold))
                    Text(stopped ? "Sambung" : "Berhenti")
                        .font(.caption2.weight(.bold))
                }
                .frame(width: 56, height: 56)
                .background(stopped ? Theme.success : Theme.critical, in: Circle())
                .foregroundStyle(.white)
                .shadow(radius: 4, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private func circleButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
