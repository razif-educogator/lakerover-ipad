import Foundation

/// What an alert looks like before it becomes a SwiftData row.
struct DraftAlert: Sendable, Equatable {
    var severity: Severity
    var kind: AlertKind
    var title: String
    var detail: String
    var primaryAction: AlertAction
    var stationIndex: Int?
}

/// Pure rule evaluation: telemetry in, alerts out. Each condition fires exactly once
/// until it clears. Durations use `Telemetry.uptime`, so the rules behave the same at 5×.
struct AlertEngine {
    struct Thresholds: Sendable {
        var lowBatteryPct: Int = 20
        var lowFlowLpm: Double = 0.8
        var lowFlowSeconds: Double = 10
        var linkLostSeconds: Double = 15
        var solarInfoW: Double = 35
    }

    private var active: Set<AlertKind> = []
    private var lowFlowSince: Double?
    private var linkLostSince: Double?

    /// `weather` is the app's single seed weather value for the active mission's lake. It is
    /// only used for alert wording — no rule depends on it.
    mutating func evaluate(
        _ t: Telemetry,
        thresholds: Thresholds = Thresholds(),
        weather: WeatherSummary? = nil
    ) -> [DraftAlert] {
        var drafts: [DraftAlert] = []

        // Battery
        if t.batteryPct < thresholds.lowBatteryPct {
            if fire(.lowBattery) {
                drafts.append(DraftAlert(
                    severity: .critical,
                    kind: .lowBattery,
                    title: "Bateri rendah — \(t.batteryPct)%",
                    detail: "Pertimbangkan pulang ke jeti sebelum stesen berikutnya.",
                    primaryAction: .returnHome,
                    stationIndex: t.currentStationIndex
                ))
            }
        } else {
            clear(.lowBattery)
        }

        // Pump flow
        if let sampling = t.sampling, sampling.phase == .sample, sampling.pumpFlowLpm < thresholds.lowFlowLpm {
            let since = lowFlowSince ?? t.uptime
            lowFlowSince = since
            if t.uptime - since >= thresholds.lowFlowSeconds, fire(.lowFlow) {
                drafts.append(DraftAlert(
                    severity: .warning,
                    kind: .lowFlow,
                    title: "Aliran sampel rendah",
                    detail: String(format: "Kadar aliran %.1f L/min, mungkin kartrij tersumbat.", sampling.pumpFlowLpm),
                    primaryAction: .retrySample,
                    stationIndex: sampling.stationIndex
                ))
            }
        } else {
            lowFlowSince = nil
            clear(.lowFlow)
        }

        // Obstacle
        if t.obstacleDetected {
            if fire(.obstacle) {
                drafts.append(DraftAlert(
                    severity: .warning,
                    kind: .obstacle,
                    title: "Halangan dikesan",
                    detail: "Objek di dalam air; rover mengelak laluan secara automatik.",
                    primaryAction: .showOnMap,
                    stationIndex: t.currentStationIndex
                ))
            }
        } else {
            clear(.obstacle)
        }

        // Link
        if t.linkQuality == 0 {
            let since = linkLostSince ?? t.uptime
            linkLostSince = since
            if t.uptime - since >= thresholds.linkLostSeconds, fire(.linkLost) {
                drafts.append(DraftAlert(
                    severity: .critical,
                    kind: .linkLost,
                    title: "Pautan rover hilang",
                    detail: "Tiada telemetri melebihi 15 saat. Rover meneruskan misi secara autonomi.",
                    primaryAction: .none,
                    stationIndex: nil
                ))
            }
        } else {
            linkLostSince = nil
            clear(.linkLost)
        }

        // Water ingress
        if t.waterIngress {
            if fire(.waterIngress) {
                drafts.append(DraftAlert(
                    severity: .critical,
                    kind: .waterIngress,
                    title: "Air masuk ke badan rover",
                    detail: "Sensor kebocoran aktif. Pulang ke jeti dengan segera.",
                    primaryAction: .returnHome,
                    stationIndex: nil
                ))
            }
        } else {
            clear(.waterIngress)
        }

        // Solar charging — exactly one alert, chosen by the shared seed weather rather than by
        // instantaneous watts, so it always agrees with the card on the Live map. The two kinds
        // clear each other, so "optimum" and "terjejas" can never be raised together.
        if let weather {
            if weather.reducesSolarCharging {
                clear(.custom)
                if fire(.reducedSolar) {
                    drafts.append(DraftAlert(
                        severity: .warning,
                        kind: .reducedSolar,
                        title: "Pengecasan solar terjejas",
                        detail: weather.isRain
                            ? "Cuaca hujan — penjanaan solar sangat rendah. Pertimbangkan hadkan jarak misi atau pulang lebih awal."
                            : "Cuaca mendung — penjanaan solar rendah. Pertimbangkan hadkan jarak misi atau pulang lebih awal.",
                        primaryAction: .viewPower,
                        stationIndex: nil
                    ))
                }
            } else if weather.isClear {
                clear(.reducedSolar)
                if fire(.custom) {
                    drafts.append(DraftAlert(
                        severity: .info,
                        kind: .custom,
                        title: weatherTitle(for: weather),
                        detail: String(format: "Panel solar menghasilkan %.0f W. Misi boleh diteruskan lebih lama.", t.solarW),
                        primaryAction: .none,
                        stationIndex: nil
                    ))
                }
            }
            // An unrecognised condition raises neither, rather than inventing a claim.
        } else {
            clear(.reducedSolar)
            clear(.custom)
        }

        return drafts
    }

    /// "Cuaca Cerah 31°C — pengecasan optimum". Only ever called for clear weather.
    private func weatherTitle(for weather: WeatherSummary) -> String {
        "Cuaca \(weather.condition) \(Int(weather.temperatureC.rounded()))°C — pengecasan optimum"
    }

    private mutating func fire(_ kind: AlertKind) -> Bool {
        guard !active.contains(kind) else { return false }
        active.insert(kind)
        return true
    }

    private mutating func clear(_ kind: AlertKind) {
        active.remove(kind)
    }
}
