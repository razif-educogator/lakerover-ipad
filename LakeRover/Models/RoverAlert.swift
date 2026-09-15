import Foundation
import SwiftData

@Model
final class RoverAlert {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var severity: Severity = Severity.info
    var kind: AlertKind = AlertKind.custom
    var title: String = ""
    var detail: String = ""
    var primaryAction: AlertAction = AlertAction.none
    var dismissed: Bool = false
    var read: Bool = false
    /// Station the alert refers to, for "Lihat di peta".
    var stationIndex: Int?

    init(
        id: UUID = UUID(),
        createdAt: Date,
        severity: Severity,
        kind: AlertKind,
        title: String,
        detail: String,
        primaryAction: AlertAction = .none,
        stationIndex: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.severity = severity
        self.kind = kind
        self.title = title
        self.detail = detail
        self.primaryAction = primaryAction
        self.stationIndex = stationIndex
    }
}
