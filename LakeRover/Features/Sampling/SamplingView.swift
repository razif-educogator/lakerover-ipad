import SwiftUI

struct SamplingView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var model = SamplingViewModel()

    private var sampling: SamplingTelemetry? { env.telemetry.latest.sampling }

    private var station: Station? {
        guard let index = sampling?.stationIndex ?? env.telemetry.latest.currentStationIndex else { return nil }
        return env.runtime.station(at: index)
    }

    private var collectsMicroparticles: Bool {
        station?.targetParameters.contains(.microparticles) ?? true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StepBar(current: sampling?.phase)
                    .padding(.vertical, 6)

                flowCard
                LiveReadingsPanel(sampling: sampling)
                MicroparticleJarCard(sampling: sampling, enabled: collectsMicroparticles)

                FillProgress(
                    filledL: sampling?.filledL ?? 0,
                    targetL: sampling?.targetL ?? 5,
                    secondsRemaining: sampling?.estimatedSecondsRemaining ?? 0
                )

                tagCard
                CameraThumb { env.router.sheet = .camera }

                HStack(spacing: 12) {
                    DestructiveButton("Hentikan") {
                        env.send(.stopSampling)
                        leave()
                    }
                    SecondaryButton("Ulang sampel") {
                        model.reset()
                        env.send(.restartSampling)
                    }
                }
                .padding(.top, 4)
            }
            .padding(Theme.gutter)
        }
        .background(Theme.screenBackground)
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { RoverToolbar() }
        .onChange(of: sampling) { _, new in
            model.sync(with: new, reader: env.tagReader)
        }
        .onChange(of: sampling == nil) { _, finished in
            // R7.8: back to Live Map once Gerak completes. Showcase mode stays put so the
            // judge controls the pace.
            if finished, !env.showcase.isActive { leave() }
        }
        .onAppear { model.sync(with: sampling, reader: env.tagReader) }
    }

    private var titleText: String {
        guard let station else { return Localization.t("Pensampelan") }
        return "Stesen \(station.shortCode) · \(statusWord)"
    }

    private var statusWord: String {
        sampling == nil ? Localization.t("Selesai") : Localization.t("Sedang diproses")
    }

    private var flowCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aliran sampel").sectionTitle()
            FlowDiagram(
                active: sampling?.phase == .sample,
                fillFraction: min(1, (sampling?.filledL ?? 0) / max(sampling?.targetL ?? 5, 0.1))
            )
            Text(flowCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let flow = sampling?.pumpFlowLpm, flow > 0, flow < 0.8 {
                Label("Aliran rendah — kartrij mungkin tersumbat", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var flowCaption: String {
        guard let sampling else { return Localization.t("Menunggu pensampelan bermula.") }
        let elapsed = Int(sampling.elapsed)
        return String(
            format: "Pam %.1f L/min · Kartrij %@ · Masa %d:%02d",
            sampling.pumpFlowLpm, sampling.cartridgeID, elapsed / 60, elapsed % 60
        )
    }

    private var tagCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tag kartrij (RFID / NFC)").sectionTitle()
            HStack(spacing: 8) {
                Image(systemName: model.tagID == nil ? "wave.3.right" : "checkmark.seal.fill")
                    .foregroundStyle(model.tagID == nil ? .secondary : Theme.success)
                Text(model.tagID ?? model.tagMessage ?? Localization.t("Menunggu langkah Tag"))
                    .font(.subheadline.weight(model.tagID == nil ? .regular : .semibold))
                Spacer()
                if model.isScanning { ProgressView().controlSize(.small) }
            }
            if model.showManualEntry {
                HStack(spacing: 8) {
                    TextField("ID kartrij", text: $model.manualTag)
                        .textFieldStyle(.roundedBorder)
                    Button("Simpan") { model.applyManualTag() }
                        .buttonStyle(.borderedProminent)
                }
            } else if model.tagID == nil {
                Button("Masukkan ID secara manual") { model.showManualEntry = true }
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func leave() {
        env.router.missionPath = []
        env.router.go(.live)
    }
}
