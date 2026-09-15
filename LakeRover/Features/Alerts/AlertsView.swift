import SwiftData
import SwiftUI

struct AlertsView: View {
    @Environment(AppEnvironment.self) private var env
    @Query(sort: \RoverAlert.createdAt, order: .reverse) private var alerts: [RoverAlert]
    @State private var filter: Severity?

    private var visible: [RoverAlert] {
        alerts.filter { !$0.dismissed && (filter == nil || $0.severity == filter) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    chips

                    if visible.isEmpty {
                        ContentUnavailableView(
                            "Tiada amaran",
                            systemImage: "checkmark.shield",
                            description: Text("Rover berjalan dalam parameter normal.")
                        )
                        .frame(height: 240)
                    } else {
                        ForEach(visible) { alert in
                            AlertCard(
                                alert: alert,
                                onPrimary: { perform(alert) },
                                onDismiss: { dismiss(alert) }
                            )
                        }
                        Text("Ketik tindakan untuk melaksanakannya terus dari senarai.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
                .padding(Theme.gutter)
            }
            .background(Theme.screenBackground)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { RoverToolbar() }
            .onAppear { env.alerts.markAllRead() }
        }
    }

    private var titleText: String {
        "Amaran (\(alerts.count { !$0.dismissed }))"
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "\(String(localized: "Semua")) (\(count(nil)))", selected: filter == nil) {
                    filter = nil
                }
                ForEach(Severity.allCases, id: \.self) { severity in
                    Chip(title: "\(label(severity)) (\(count(severity)))", selected: filter == severity) {
                        filter = severity
                    }
                }
            }
        }
    }

    private func label(_ severity: Severity) -> String {
        switch severity {
        case .critical: String(localized: "Kritikal")
        case .warning: String(localized: "Amaran")
        case .info: String(localized: "Maklumat")
        }
    }

    private func count(_ severity: Severity?) -> Int {
        alerts.count { !$0.dismissed && (severity == nil || $0.severity == severity) }
    }

    /// R10.3 — the action runs straight from the list.
    private func perform(_ alert: RoverAlert) {
        switch alert.primaryAction {
        case .returnHome:
            env.send(.returnHome)
            env.router.go(.live)
        case .retrySample:
            env.send(.restartSampling)
            env.router.pushMission(.sampling)
        case .showOnMap:
            let station = alert.stationIndex.flatMap { env.runtime.station(at: $0) }
            env.router.focusOnMap(stationID: station?.id)
        case .none:
            break
        }
        dismiss(alert)
    }

    private func dismiss(_ alert: RoverAlert) {
        alert.dismissed = true
        alert.read = true
        try? env.context.save()
    }
}
