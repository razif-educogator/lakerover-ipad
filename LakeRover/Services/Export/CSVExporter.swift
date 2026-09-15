import Foundation

/// `Sample` → RFC 4180 CSV, written to a temporary file for `ShareLink`.
enum CSVExporter {
    static let header = "kod,stesen,zon,masa,latitud,longitud,isipadu_l,tag,status,kekeruhan_ntu,suhu_c,ph,do_mgl,nota"

    static func csv(for samples: [Sample]) -> String {
        var lines = [header]
        let formatter = ISO8601DateFormatter()
        for sample in samples.sorted(by: { $0.takenAt < $1.takenAt }) {
            let fields: [String] = [
                sample.code,
                sample.station?.name ?? "",
                sample.station?.zone ?? "",
                formatter.string(from: sample.takenAt),
                String(format: "%.6f", sample.latitude),
                String(format: "%.6f", sample.longitude),
                String(format: "%.2f", sample.volumeL),
                sample.tagID ?? "",
                sample.status.rawValue,
                sample.turbidityNTU.map { String(format: "%.2f", $0) } ?? "",
                sample.temperatureC.map { String(format: "%.2f", $0) } ?? "",
                sample.pH.map { String(format: "%.2f", $0) } ?? "",
                sample.dissolvedOxygenMgL.map { String(format: "%.2f", $0) } ?? "",
                sample.studentNote
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n")
    }

    static func write(samples: [Sample], missionName: String) throws -> URL {
        let safeName = missionName
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LakeRover-\(safeName).csv")
        try csv(for: samples).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
