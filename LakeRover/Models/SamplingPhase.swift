import SwiftUI

/// The six steps of the sampling process, shared by the Sampling screen and the AR model.
enum SamplingPhase: Int, CaseIterable, Codable, Sendable, Comparable {
    case arrive = 0, register, sample, tag, store, move

    static func < (lhs: SamplingPhase, rhs: SamplingPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: LocalizedStringKey {
        switch self {
        case .arrive: "Tiba"
        case .register: "Daftar"
        case .sample: "Sampel"
        case .tag: "Tag"
        case .store: "Simpan"
        case .move: "Gerak"
        }
    }

    /// `samplingStep1` … `samplingStep6` — the Reality Composer notification identifiers.
    var notificationIdentifier: String { "samplingStep\(rawValue + 1)" }

    init?(notificationIdentifier: String) {
        guard notificationIdentifier.hasPrefix("samplingStep"),
              let n = Int(notificationIdentifier.dropFirst("samplingStep".count)),
              let phase = SamplingPhase(rawValue: n - 1)
        else { return nil }
        self = phase
    }
}
