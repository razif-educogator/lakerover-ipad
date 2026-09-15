import Foundation
import SwiftData

/// Single-row settings store.
@Model
final class AppSettings {
    var language: String = AppLanguage.ms.rawValue
    var autoReturnEnabled: Bool = true
    var autoReturnThreshold: Int = 25
    var autonomousMode: Bool = true
    var powerSaveMode: Bool = false
    var cloudSync: Bool = false
    var notificationLevel: NotificationLevel = NotificationLevel.criticalOnly
    var mapStyle: MapLayer = MapLayer.satellite
    var stationSpacingM: Int = 400
    var lowBatteryThreshold: Int = 20
    var roverName: String = "LakeRover-01"

    init() {}

    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: language) ?? .ms }
        set { language = newValue.rawValue }
    }
}
