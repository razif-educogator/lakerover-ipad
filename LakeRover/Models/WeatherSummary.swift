import Foundation

struct WeatherSummary: Sendable, Equatable, Codable {
    var condition: String
    var temperatureC: Double
    var symbolName: String

    var text: String { "\(condition) \(Int(temperatureC.rounded()))°C" }
}
