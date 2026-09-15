import SwiftUI

/// A water-quality parameter the rover can measure.
/// `microparticles` is the odd one out: it has no field reading, only a lab result.
enum Parameter: String, Codable, CaseIterable, Sendable, Identifiable {
    case turbidity, temperature, pH, dissolvedOxygen, conductivity, microparticles

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .turbidity: "Kekeruhan"
        case .temperature: "Suhu"
        case .pH: "pH"
        case .dissolvedOxygen: "Oksigen terlarut (DO)"
        case .conductivity: "Konduktiviti"
        case .microparticles: "Mikropartikel"
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
        case .microparticles: "Mikropartikel"
        }
    }

    var unit: String {
        switch self {
        case .turbidity: "NTU"
        case .temperature: "°C"
        case .pH: ""
        case .dissolvedOxygen: "mg/L"
        case .conductivity: "µS/cm"
        case .microparticles: "partikel/L"
        }
    }

    /// No sensor reads this in the field — a jar is filled and sent away.
    var isLabAnalysis: Bool { self == .microparticles }

    /// Parameters with a live sensor value, shown in the Sampling readings panel.
    static let charted: [Parameter] = [.turbidity, .temperature, .pH, .dissolvedOxygen]

    /// Parameters selectable on the Insights screen — field sensors plus the lab result.
    static let insightsSelectable: [Parameter] = charted + [.microparticles]

    func format(_ value: Double) -> String {
        let digits = self == .microparticles ? 0 : 1
        let text = String(format: "%.\(digits)f", value)
        return unit.isEmpty ? text : "\(text) \(unit)"
    }
}
