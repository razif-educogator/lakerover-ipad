import Foundation
import Observation

/// WeatherKit needs an entitlement and a network, neither of which the demo has, so the
/// provider reads `seed/weather.json`. The interface is the one a WeatherKit call would use.
@MainActor
@Observable
final class WeatherProvider {
    private var byLake: [String: WeatherSummary] = [:]

    init() {
        struct File: Decodable { var byLake: [String: WeatherSummary] }
        if let url = Bundle.main.url(forResource: "weather", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data) {
            byLake = file.byLake
        }
    }

    /// `nil` when there is no data for the lake — the mission row then shows
    /// "Cuaca tidak tersedia" (R2.6).
    func summary(forLake lake: String) -> WeatherSummary? {
        byLake[lake]
    }
}
