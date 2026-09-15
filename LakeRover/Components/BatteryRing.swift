import SwiftUI

struct BatteryRing: View {
    var percentage: Int
    var ratePctPerMin: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: max(0.01, Double(percentage) / 100))
                    .stroke(tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: percentage)
                VStack(spacing: 0) {
                    Text("\(percentage)%")
                        .font(Theme.bigNumberFont)
                        .monospacedDigit()
                }
            }
            .frame(width: 132, height: 132)

            Label(rateText, systemImage: ratePctPerMin >= 0 ? "bolt.fill" : "arrow.down")
                .font(.caption.weight(.medium))
                .foregroundStyle(ratePctPerMin >= 0 ? Theme.success : Theme.warning)
        }
    }

    private var tint: Color {
        if percentage < 20 { return Theme.critical }
        if percentage < 40 { return Theme.warning }
        return Theme.success
    }

    private var rateText: String {
        let word = ratePctPerMin >= 0
            ? Localization.t("Mengecas")
            : Localization.t("Menggunakan")
        return String(format: "%@ %+.1f %%/min", word, ratePctPerMin)
    }
}
