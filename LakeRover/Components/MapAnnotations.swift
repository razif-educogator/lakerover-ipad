import SwiftUI

/// Numbered station pin: waiting, current or done (R3.4).
struct StationAnnotationView: View {
    var station: Station
    var isCurrent: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: isCurrent ? 32 : 26, height: isCurrent ? 32 : 26)
                .shadow(radius: 2, y: 1)
            if station.status == .done {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } else {
                Text(station.shortCode)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(.white, lineWidth: isCurrent ? 2.5 : 1.5)
                .frame(width: isCurrent ? 32 : 26, height: isCurrent ? 32 : 26)
        )
    }

    private var fill: Color {
        if station.status == .done { return Theme.success }
        if station.status == .skipped { return Theme.warning }
        return isCurrent ? Theme.accent : Color(.systemGray)
    }
}

/// Heading-oriented rover marker.
struct RoverAnnotationView: View {
    var headingDeg: Double
    var moving: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(moving ? 0.22 : 0.12))
                .frame(width: 46, height: 46)
            Image(systemName: "location.north.fill")
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .rotationEffect(.degrees(headingDeg))
                .padding(7)
                .background(.white, in: Circle())
                .shadow(radius: 3, y: 1)
        }
        .accessibilityLabel("Kedudukan rover")
    }
}
