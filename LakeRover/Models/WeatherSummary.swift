import Foundation

struct WeatherSummary: Sendable, Equatable, Codable {
    var condition: String
    var temperatureC: Double
    var symbolName: String

    var text: String { "\(condition) \(Int(temperatureC.rounded()))°C" }

    // Seed conditions are "Cerah", "Mendung" and "Hujan". Classified here rather than in the
    // alert engine so every screen agrees on what counts as poor charging weather.
    // `nonisolated` so pure, off-main callers can use them.

    nonisolated var isRain: Bool {
        condition.localizedCaseInsensitiveContains("hujan")
    }

    nonisolated var isOvercast: Bool {
        condition.localizedCaseInsensitiveContains("mendung")
    }

    nonisolated var isClear: Bool {
        condition.localizedCaseInsensitiveContains("cerah")
    }

    /// Cloud and rain cut solar output. "Cerah" deliberately does not.
    nonisolated var reducesSolarCharging: Bool {
        isRain || isOvercast
    }
}
