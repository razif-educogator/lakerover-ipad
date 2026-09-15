import SwiftUI

/// Mikropartikel is not a sensor reading — water is filtered into a jar on the rover and the
/// jar goes to a lab. This tracks where a given sample is in that second phase.
enum LabStatus: String, Codable, CaseIterable, Sendable {
    case notCollected
    case awaiting
    case received
    case done

    var label: LocalizedStringKey {
        switch self {
        case .notCollected: "Tidak dikumpul"
        case .awaiting: "Menunggu keputusan makmal"
        case .received: "Diterima"
        case .done: "Selesai"
        }
    }

    /// Short form for chips and badges, where the full sentence does not fit.
    var shortLabel: LocalizedStringKey {
        switch self {
        case .notCollected: "Tidak dikumpul"
        case .awaiting: "Menunggu makmal"
        case .received: "Diterima"
        case .done: "Selesai"
        }
    }

    var symbol: String {
        switch self {
        case .notCollected: "circle.dashed"
        case .awaiting: "clock"
        case .received: "shippingbox"
        case .done: "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notCollected: Theme.waiting
        case .awaiting: Theme.warning
        case .received: Theme.accent
        case .done: Theme.success
        }
    }

    // `nonisolated` because the SwiftData model layer reads these outside the main actor.

    /// `true` once a jar exists, i.e. the field half of the flow happened.
    nonisolated var isCollected: Bool { self != .notCollected }

    /// `true` only when numbers have come back and can be charted.
    nonisolated var hasResult: Bool { self == .done }
}
