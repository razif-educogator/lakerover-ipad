import SwiftUI

// Small status enums used by the SwiftData models. Grouped in one file on purpose:
// each is two lines of data plus its presentation helpers.

enum MissionState: String, Codable, CaseIterable, Sendable {
    case draft, planned, active, paused, completed

    var label: LocalizedStringKey {
        switch self {
        case .draft: "Draf"
        case .planned: "Dirancang"
        case .active: "Sedang berjalan"
        case .paused: "Dijeda"
        case .completed: "Lengkap"
        }
    }
}

enum StationStatus: String, Codable, CaseIterable, Sendable {
    case waiting, inProgress, done, skipped

    var label: LocalizedStringKey {
        switch self {
        case .waiting: "Menunggu"
        case .inProgress: "Sedang diproses"
        case .done: "Selesai"
        case .skipped: "Dilangkau"
        }
    }

    var symbol: String {
        switch self {
        case .waiting: "circle"
        case .inProgress: "arrow.triangle.2.circlepath"
        case .done: "checkmark.circle.fill"
        case .skipped: "arrow.uturn.right"
        }
    }

    var tint: Color {
        switch self {
        case .waiting: Theme.waiting
        case .inProgress: Theme.accent
        case .done: Theme.success
        case .skipped: Theme.warning
        }
    }
}

enum SampleStatus: String, Codable, CaseIterable, Sendable {
    case waiting, inProgress, done, cancelled

    var label: LocalizedStringKey {
        switch self {
        case .waiting: "Menunggu"
        case .inProgress: "Diproses"
        case .done: "Selesai"
        case .cancelled: "Dibatalkan"
        }
    }

    var tint: Color {
        switch self {
        case .waiting: Theme.waiting
        case .inProgress: Theme.accent
        case .done: Theme.success
        case .cancelled: Theme.critical
        }
    }
}

enum Severity: String, Codable, CaseIterable, Sendable {
    case critical, warning, info

    var label: LocalizedStringKey {
        switch self {
        case .critical: "Kritikal"
        case .warning: "Amaran"
        case .info: "Maklumat"
        }
    }

    var tint: Color {
        switch self {
        case .critical: Theme.critical
        case .warning: Theme.warning
        case .info: Theme.accent
        }
    }

    var symbol: String {
        switch self {
        case .critical: "exclamationmark.triangle.fill"
        case .warning: "exclamationmark.triangle"
        case .info: "info.circle"
        }
    }
}

enum AlertKind: String, Codable, CaseIterable, Sendable {
    case lowBattery, lowFlow, obstacle, linkLost, waterIngress, custom
}

enum AlertAction: String, Codable, CaseIterable, Sendable {
    case returnHome, retrySample, showOnMap, none

    var label: LocalizedStringKey {
        switch self {
        case .returnHome: "Pulang ke jeti"
        case .retrySample: "Ulang sampel"
        case .showOnMap: "Lihat di peta"
        case .none: ""
        }
    }
}

enum NotificationLevel: String, Codable, CaseIterable, Sendable {
    case all, criticalOnly, off

    var label: LocalizedStringKey {
        switch self {
        case .all: "Semua amaran"
        case .criticalOnly: "Kritikal sahaja"
        case .off: "Dimatikan"
        }
    }
}

enum MapLayer: String, Codable, CaseIterable, Sendable {
    case standard, satellite, depth, turbidity

    var label: LocalizedStringKey {
        switch self {
        case .standard: "Standard"
        case .satellite: "Satelit"
        case .depth: "Kedalaman"
        case .turbidity: "Kekeruhan"
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case ms, en

    var label: String {
        switch self {
        case .ms: "Bahasa Malaysia"
        case .en: "English"
        }
    }

    var locale: Locale { Locale(identifier: rawValue == "ms" ? "ms_MY" : "en_MY") }
}
