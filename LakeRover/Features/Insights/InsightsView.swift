import SwiftUI

struct InsightsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var model = InsightsViewModel()
    @State private var pdfURL: URL?

    private var mission: Mission? { env.runtime.activeMission ?? SeedDataLoader.demoMission(in: env.context) }
    private var previous: Mission? { mission.flatMap { env.runtime.previousMission(for: $0) } }
    private var threshold: Double { mission?.turbidityThresholdNTU ?? 15 }

    private var current: [StationPoint] { model.series(for: mission) }
    private var comparison: [StationPoint] { model.comparisonSeries(previous: previous) }
    private var exceeded: [StationPoint] { model.exceeding(current, threshold: threshold) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    chips

                    if current.isEmpty {
                        ContentUnavailableView(
                            "Belum ada data",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Selesaikan sekurang-kurangnya satu stesen untuk melihat trend.")
                        )
                        .frame(height: 220)
                    } else {
                        chartCard
                        statsRow
                        heatMapAndCards
                        exportRow
                    }
                }
                .padding(Theme.gutter)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Data & insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { RoverToolbar() }
            .task(id: taskKey) { pdfURL = PDFReportRenderer.render(reportData) }
        }
    }

    private var taskKey: String {
        "\(model.parameter.rawValue)-\(model.range.rawValue)-\(current.count)-\(mission?.samples.count ?? 0)"
    }

    private var chips: some View {
        HStack(alignment: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Parameter.insightsSelectable) { parameter in
                        Chip(title: parameter.shortLabel, selected: model.parameter == parameter) {
                            model.parameter = parameter
                        }
                    }
                }
            }
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                ForEach(InsightsRange.allCases, id: \.self) { range in
                    Chip(title: range.label, selected: model.range == range) {
                        model.range = range
                    }
                }
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle).font(.subheadline.weight(.semibold))
            TrendChart(
                parameter: model.parameter,
                current: current,
                previous: comparison,
                threshold: threshold
            )
            if !comparison.isEmpty {
                HStack(spacing: 14) {
                    legendDot(color: Theme.accent, label: Localization.t("Misi ini"))
                    legendDot(color: Theme.accent.opacity(0.35), label: Localization.t("Misi lalu"))
                }
            }
            if model.parameter.isLabAnalysis {
                Label(
                    Localization.t("Hanya stesen dengan keputusan makmal dipaparkan."),
                    systemImage: "flask.fill"
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                if let awaiting = model.awaitingLabText(for: mission) {
                    Label(awaiting, systemImage: "clock")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.warning)
                }
            }
        }
        .cardStyle()
    }

    private var chartTitle: String {
        "\(model.parameter.shortLabel) mengikut stesen\(model.parameter.unit.isEmpty ? "" : " (\(model.parameter.unit))")"
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatCard(
                title: "Purata misi",
                value: model.average(current).map { model.parameter.format($0) } ?? "—",
                footnote: changeFootnote,
                footnoteTint: changeTint
            )
            StatCard(
                title: "Stesen tertinggi",
                value: model.highest(current).map { "\($0.code)" } ?? "—",
                footnote: model.highest(current).map { "\($0.name) · \(model.parameter.format($0.value))" }
            )
        }
    }

    private var changeFootnote: String? {
        guard let change = model.change(current: current, previous: comparison) else { return nil }
        let sign = change >= 0 ? "+" : "−"
        return String(format: "%@%.1f vs misi lalu", sign, abs(change))
    }

    private var changeTint: Color? {
        guard let change = model.change(current: current, previous: comparison) else { return nil }
        if model.parameter == .turbidity { return change > 0 ? Theme.critical : Theme.success }
        return nil
    }

    private var heatMapAndCards: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Peta haba tasik").sectionTitle()
                HeatMapGrid(points: current)
                if model.parameter.isLabAnalysis, !model.awaitingLab(for: mission).isEmpty {
                    Text("Corak separa — \(model.awaitingLab(for: mission).count) stesen masih menunggu makmal.")
                        .font(.caption2)
                        .foregroundStyle(Theme.warning)
                }
            }
            .cardStyle()
            .frame(maxWidth: 260)

            VStack(spacing: 10) {
                if let text = model.attentionText(for: exceeded, threshold: threshold) {
                    AttentionCard(text: text)
                }
                if let text = model.microparticleRecommendation(current: current, mission: mission) {
                    RecommendationCard(text: text)
                } else if let text = model.recommendation(for: exceeded, threshold: threshold) {
                    RecommendationCard(text: text)
                } else {
                    RecommendationCard(
                        text: Localization.t("Semua stesen dalam had. Teruskan pemantauan dua minggu sekali.")
                    )
                }
            }
        }
    }

    private var exportRow: some View {
        HStack(spacing: 12) {
            if let pdfURL {
                ShareLink(item: pdfURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.richtext")
                        Text("Jana laporan PDF")
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
                }
                ShareLink(item: pdfURL) {
                    Text("Kongsi")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
    }

    private var reportData: ReportData {
        let rows = (mission?.orderedSamples ?? []).filter { $0.status == .done }.map { sample in
            ReportData.Row(
                id: sample.id.uuidString,
                code: sample.code,
                station: sample.station.map { "\($0.shortCode) · \($0.name)" } ?? "—",
                time: sample.takenAt.formatted(date: .omitted, time: .shortened),
                turbidity: sample.turbidityNTU.map { String(format: "%.1f", $0) } ?? "—",
                temperature: sample.temperatureC.map { String(format: "%.1f", $0) } ?? "—",
                pH: sample.pH.map { String(format: "%.1f", $0) } ?? "—",
                dissolvedOxygen: sample.dissolvedOxygenMgL.map { String(format: "%.1f", $0) } ?? "—"
            )
        }
        return ReportData(
            missionName: mission?.name ?? "—",
            lakeName: mission?.lakeName ?? "—",
            dateText: (mission?.plannedDate ?? Date()).formatted(date: .long, time: .omitted),
            stationCount: mission?.stations.count ?? 0,
            sampleCount: rows.count,
            parameter: model.parameter,
            threshold: threshold,
            current: current,
            previous: comparison,
            averageText: model.average(current).map { model.parameter.format($0) } ?? "—",
            changeText: changeFootnote ?? "—",
            highestText: model.highest(current).map { "\($0.code) · \(model.parameter.format($0.value))" } ?? "—",
            recommendation: model.recommendation(for: exceeded, threshold: threshold),
            rows: rows
        )
    }
}
