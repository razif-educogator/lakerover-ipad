import SwiftUI

struct SampleDetailPane: View {
    var sample: Sample
    var csvURL: URL?
    var onShowOnMap: () -> Void

    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(sample.code)
                        .font(.title3.weight(.bold))
                    Spacer()
                    StatusPill(
                        text: sample.status.label,
                        symbol: sample.status == .done ? "checkmark.circle.fill" : "circle",
                        tint: sample.status.tint
                    )
                }

                VStack(spacing: 0) {
                    KeyValueRow("Lokasi", String(format: "%.4f, %.4f", sample.latitude, sample.longitude))
                    Divider()
                    KeyValueRow("Masa", sample.takenAt.formatted(date: .abbreviated, time: .shortened))
                    Divider()
                    KeyValueRow("Isipadu", String(format: "%.1f L", sample.volumeL))
                    Divider()
                    KeyValueRow("Tag RFID", sample.tagID ?? "—")
                    Divider()
                    KeyValueRow("Stesen", sample.station.map { "\($0.shortCode) · \($0.name)" } ?? "—")
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data sensor").sectionTitle()
                    SensorTable(
                        turbidityNTU: sample.turbidityNTU,
                        temperatureC: sample.temperatureC,
                        pH: sample.pH,
                        dissolvedOxygenMgL: sample.dissolvedOxygenMgL
                    )
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nota pelajar").sectionTitle()
                    TextField(
                        "Contoh: air agak keruh berhampiran jeti…",
                        text: Binding(
                            get: { sample.studentNote },
                            set: { sample.studentNote = $0; try? env.context.save() }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                    .textFieldStyle(.roundedBorder)
                }
                .cardStyle()

                VStack(spacing: 10) {
                    SecondaryButton("Lihat di peta", action: onShowOnMap)
                    if let csvURL {
                        ShareLink(item: csvURL) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Eksport CSV")
                            }
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.accent, in: Capsule())
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .background(Theme.screenBackground)
    }
}
