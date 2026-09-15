import Charts
import SwiftUI

struct ReportData {
    struct Row: Identifiable {
        var id: String
        var code: String
        var station: String
        var time: String
        var turbidity: String
        var temperature: String
        var pH: String
        var dissolvedOxygen: String
    }

    var missionName: String
    var lakeName: String
    var dateText: String
    var stationCount: Int
    var sampleCount: Int
    var parameter: Parameter
    var threshold: Double
    var current: [StationPoint]
    var previous: [StationPoint]
    var averageText: String
    var changeText: String
    var highestText: String
    var recommendation: String?
    var rows: [Row]
}

/// A4 portrait page rendered to PDF by `PDFReportRenderer` (R9.5).
struct ReportPage: View {
    var data: ReportData

    static let size = CGSize(width: 595, height: 842)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    LogoLockup(compact: true)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(data.lakeName).font(.headline)
                    Text(data.dateText).font(.caption).foregroundStyle(.secondary)
                    Text("\(data.stationCount) stesen · \(data.sampleCount) sampel")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 10) {
                summaryBox(title: "Purata misi", value: data.averageText)
                summaryBox(title: "Berbanding misi lalu", value: data.changeText)
                summaryBox(title: "Stesen tertinggi", value: data.highestText)
            }

            Text("Kekeruhan mengikut stesen (\(data.parameter.unit))")
                .font(.subheadline.weight(.semibold))

            Chart {
                ForEach(data.previous) { point in
                    LineMark(
                        x: .value("Stesen", point.code),
                        y: .value("Nilai", point.value),
                        series: .value("Misi", "Sebelum")
                    )
                    .foregroundStyle(Theme.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
                ForEach(data.current) { point in
                    LineMark(
                        x: .value("Stesen", point.code),
                        y: .value("Nilai", point.value),
                        series: .value("Misi", "Kini")
                    )
                    .foregroundStyle(Theme.accent)
                    .symbol { Circle().fill(Theme.accent).frame(width: 5, height: 5) }
                }
                RuleMark(y: .value("Had", data.threshold))
                    .foregroundStyle(Theme.critical.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartLegend(.hidden)
            .frame(height: 160)

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Peta haba tasik").font(.subheadline.weight(.semibold))
                    HeatMapGrid(points: data.current, columns: 6, rows: 5)
                        .frame(width: 170)
                }
                VStack(alignment: .leading, spacing: 8) {
                    if let recommendation = data.recommendation {
                        RecommendationCard(text: recommendation)
                    }
                    Text("“Dari Tasik ke Data. Dari Data ke Tindakan.”")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Rekod sampel").font(.subheadline.weight(.semibold))
            table

            Spacer(minLength: 0)

            Text("LakeRover · MCKK Robotics · laporan dijana secara automatik")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: ReportPage.size.width, height: ReportPage.size.height)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    private func summaryBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(white: 0.95), in: RoundedRectangle(cornerRadius: 8))
    }

    private var table: some View {
        VStack(spacing: 0) {
            headerRow
            ForEach(data.rows) { row in
                HStack(spacing: 0) {
                    cell(row.code, width: 70, bold: true)
                    cell(row.station, width: 110)
                    cell(row.time, width: 70)
                    cell(row.turbidity, width: 62)
                    cell(row.temperature, width: 62)
                    cell(row.pH, width: 50)
                    cell(row.dissolvedOxygen, width: 60)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(white: 0.9)).frame(height: 0.5)
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            cell("Kod", width: 70, bold: true)
            cell("Stesen", width: 110, bold: true)
            cell("Masa", width: 70, bold: true)
            cell("NTU", width: 62, bold: true)
            cell("°C", width: 62, bold: true)
            cell("pH", width: 50, bold: true)
            cell("DO", width: 60, bold: true)
        }
        .background(Color(white: 0.93))
    }

    private func cell(_ text: String, width: CGFloat, bold: Bool = false) -> some View {
        Text(text)
            .font(.caption2.weight(bold ? .semibold : .regular))
            .lineLimit(1)
            .frame(width: width, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 3)
    }
}
