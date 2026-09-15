import SwiftUI

/// A water-quality parameter the rover can measure.
enum Parameter: String, Codable, CaseIterable, Sendable, Identifiable {
    case turbidity, temperature, pH, dissolvedOxygen, conductivity

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .turbidity: "Kekeruhan"
        case .temperature: "Suhu"
        case .pH: "pH"
        case .dissolvedOxygen: "Oksigen terlarut (DO)"
        case .conductivity: "Konduktiviti"
        }
    }

    /// Short form used in chips and table headers.
    var shortLabel: String {
        switch self {
        case .turbidity: "Kekeruhan"
        case .temperature: "Suhu"
        case .pH: "pH"
        case .dissolvedOxygen: "DO"
        case .conductivity: "EC"
        }
    }

    var unit: String {
        switch self {
        case .turbidity: "NTU"
        case .temperature: "°C"
        case .pH: ""
        case .dissolvedOxygen: "mg/L"
        case .conductivity: "µS/cm"
        }
    }

    /// Parameters shown on the Insights screen.
    static let charted: [Parameter] = [.turbidity, .temperature, .pH, .dissolvedOxygen]

    func format(_ value: Double) -> String {
        let digits = self == .turbidity || self == .temperature || self == .pH ? 1 : 1
        let text = String(format: "%.\(digits)f", value)
        return unit.isEmpty ? text : "\(text) \(unit)"
    }
}
