import Foundation
import Observation

enum MainTab: String, Hashable, CaseIterable {
    case live, misi, sampel, data, amaran

    var title: String {
        switch self {
        case .live: "Live"
        case .misi: "Misi"
        case .sampel: "Sampel"
        case .data: "Data"
        case .amaran: "Amaran"
        }
    }

    var symbol: String {
        switch self {
        case .live: "dot.radiowaves.left.and.right"
        case .misi: "list.bullet.rectangle"
        case .sampel: "testtube.2"
        case .data: "chart.xyaxis.line"
        case .amaran: "exclamationmark.triangle"
        }
    }
}

/// Push destinations inside the Misi tab.
enum MissionRoute: Hashable {
    case progress
    case sampling
    case editor
    case roverModel
    /// Mission Picker reached from Mission Progress ("Tukar tasik"), so the lake list is
    /// available mid-demo without ending the active mission.
    case picker
}

enum AppSheet: Identifiable, Hashable {
    case power
    case settings
    case camera
    case stationDetail(UUID)

    var id: String {
        switch self {
        case .power: "power"
        case .settings: "settings"
        case .camera: "camera"
        case .stationDetail(let id): "station-\(id.uuidString)"
        }
    }
}

/// Owns everything about *where* the app is. Showcase mode drives this object.
@MainActor
@Observable
final class AppRouter {
    var tab: MainTab = .live
    var missionPath: [MissionRoute] = []
    var sheet: AppSheet?

    /// Station the Live map should centre on next (set by "Lihat di peta").
    var mapFocusStationID: UUID?

    func go(_ tab: MainTab) {
        sheet = nil
        if tab != .misi { missionPath = [] }
        self.tab = tab
    }

    func pushMission(_ route: MissionRoute) {
        sheet = nil
        tab = .misi
        missionPath = [route]
    }

    func focusOnMap(stationID: UUID?) {
        mapFocusStationID = stationID
        go(.live)
    }
}
