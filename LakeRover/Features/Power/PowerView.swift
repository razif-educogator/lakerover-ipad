import SwiftUI

struct PowerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    private var telemetry: Telemetry { env.telemetry.latest }
    private var settings: AppSettings { env.settings }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 8) {
                            Text("Bateri utama").sectionTitle()
                            BatteryRing(
                                percentage: telemetry.batteryPct,
                                ratePctPerMin: telemetry.batteryRatePctPerMin
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .cardStyle()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tenaga solar").sectionTitle()
                            SolarBars(samples: env.telemetry.solarHistory, currentW: telemetry.solarW)
                        }
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                    }

                    RuntimeCard(
                        runtimeText: env.telemetry.runtimeText,
                        stationsCovered: stationsCovered
                    )

                    ConsumptionList(breakdown: telemetry.powerBreakdown)
                        .cardStyle()

                    VStack(spacing: 4) {
                        SettingToggleRow(
                            title: "Mod operasi autonomi",
                            subtitle: String(localized: "Rover meneruskan misi walaupun pautan terputus"),
                            isOn: Binding(
                                get: { settings.autonomousMode },
                                set: { settings.autonomousMode = $0; env.send(.setAutonomous($0)); save() }
                            )
                        )
                        Divider()
                        SettingToggleRow(
                            title: "Pulang automatik",
                            subtitle: String(format: String(localized: "Bateri di bawah %d%%"), settings.autoReturnThreshold),
                            isOn: Binding(
                                get: { settings.autoReturnEnabled },
                                set: {
                                    settings.autoReturnEnabled = $0
                                    env.send(.setAutoReturn(enabled: $0, thresholdPct: settings.autoReturnThreshold))
                                    save()
                                }
                            )
                        )
                        if settings.autoReturnEnabled {
                            Stepper(
                                value: Binding(
                                    get: { settings.autoReturnThreshold },
                                    set: {
                                        settings.autoReturnThreshold = $0
                                        env.send(.setAutoReturn(enabled: true, thresholdPct: $0))
                                        save()
                                    }
                                ),
                                in: 10...50,
                                step: 5
                            ) {
                                Text("Had pulang automatik: \(settings.autoReturnThreshold)%")
                                    .font(.caption)
                            }
                        }
                        Divider()
                        SettingToggleRow(
                            title: "Mod jimat kuasa",
                            subtitle: String(localized: "Kurangkan kadar telemetri dan kamera"),
                            isOn: Binding(
                                get: { settings.powerSaveMode },
                                set: { settings.powerSaveMode = $0; env.send(.setPowerSave($0)); save() }
                            )
                        )
                    }
                    .cardStyle()
                }
                .padding(Theme.gutter)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Tenaga")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }

    /// R11.2 — how many of the remaining stations the battery covers.
    private var stationsCovered: Int {
        let remaining = env.runtime.activeMission?.orderedStations.count { $0.status != .done } ?? 0
        let secondsPerStation: Double = 95
        let covered = Int(env.telemetry.estimatedRuntime / secondsPerStation)
        return min(remaining, max(0, covered))
    }

    private func save() {
        try? env.context.save()
    }
}
