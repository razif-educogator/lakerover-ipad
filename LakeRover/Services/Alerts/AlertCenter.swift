import Foundation
import Observation
import SwiftData

/// Turns telemetry into persisted alerts, keeps the unread count and the critical banner.
@MainActor
@Observable
final class AlertCenter {
    var banner: RoverAlert?
    private(set) var unreadCount = 0

    private var engine = AlertEngine()
    private let context: ModelContext
    private var bannerTimer: Task<Void, Never>?

    init(context: ModelContext) {
        self.context = context
        refreshUnreadCount()
    }

    func ingest(_ telemetry: Telemetry, thresholds: AlertEngine.Thresholds) {
        let drafts = engine.evaluate(telemetry, thresholds: thresholds)
        guard !drafts.isEmpty else { return }
        for draft in drafts {
            let alert = RoverAlert(
                createdAt: Date(),
                severity: draft.severity,
                kind: draft.kind,
                title: draft.title,
                detail: draft.detail,
                primaryAction: draft.primaryAction,
                stationIndex: draft.stationIndex
            )
            context.insert(alert)
            if draft.severity == .critical { show(banner: alert) }
        }
        try? context.save()
        refreshUnreadCount()
    }

    func markAllRead() {
        for alert in fetchAll() where !alert.read {
            alert.read = true
        }
        try? context.save()
        refreshUnreadCount()
    }

    func dismissBanner() {
        bannerTimer?.cancel()
        bannerTimer = nil
        banner = nil
    }

    func reset() {
        engine = AlertEngine()
        dismissBanner()
        for alert in fetchAll() { context.delete(alert) }
        try? context.save()
        refreshUnreadCount()
    }

    private func show(banner alert: RoverAlert) {
        banner = alert
        bannerTimer?.cancel()
        bannerTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.banner = nil
        }
    }

    private func fetchAll() -> [RoverAlert] {
        (try? context.fetch(FetchDescriptor<RoverAlert>())) ?? []
    }

    private func refreshUnreadCount() {
        unreadCount = fetchAll().count { !$0.read && !$0.dismissed }
    }
}
