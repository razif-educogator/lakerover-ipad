import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    private var settings: AppSettings { env.settings }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rover & sambungan") {
                    KeyValueRow("Rover", env.roverName)
                    KeyValueRow("Pautan", env.client.isDemo ? "Demo (disimulasikan)" : "4G")
                    KeyValueRow("Kelajuan simulasi", String(format: "%.0f×", env.client.speedMultiplier))
                    Stepper("Kelajuan demo") {
                        env.client.speedMultiplier = min(10, env.client.speedMultiplier + 1)
                    } onDecrement: {
                        env.client.speedMultiplier = max(1, env.client.speedMultiplier - 1)
                    }
                }

                Section("Misi & stesen") {
                    Stepper(
                        "Jarak stesen: \(settings.stationSpacingM) m",
                        value: binding(\.stationSpacingM),
                        in: 100...1000,
                        step: 50
                    )
                    KeyValueRow("Misi aktif", env.runtime.activeMission?.lakeName ?? "Tiada")
                }

                Section("Sensor & kalibrasi") {
                    KeyValueRow("Kekeruhan", "Kalibrasi 3 hari lalu")
                    KeyValueRow("pH", "Kalibrasi 3 hari lalu")
                    KeyValueRow("Isipadu kartrij", "5.0 L")
                }

                Section("Tag kartrij (RFID / NFC)") {
                    KeyValueRow("Mod", FeatureFlags.nfcEnabled ? "Imbas automatik" : "Simulasi")
                    Text("Pembaca NFC dimatikan dalam binaan demo; ID kartrij diambil daripada skrip misi.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data & awan") {
                    Toggle("Selaras ke iCloud / Drive", isOn: binding(\.cloudSync))
                        .tint(Theme.accent)
                    Text(settings.cloudSync
                        ? "Penyelarasan iCloud akan diaktifkan dalam binaan berikutnya; eksport Drive melalui helaian kongsi."
                        : "Data disimpan pada peranti ini sahaja.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Notifikasi") {
                    Picker("Tahap amaran", selection: binding(\.notificationLevel)) {
                        ForEach(NotificationLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    Stepper(
                        "Had bateri rendah: \(settings.lowBatteryThreshold)%",
                        value: binding(\.lowBatteryThreshold),
                        in: 10...40,
                        step: 5
                    )
                }

                Section("Peta") {
                    Picker("Lapisan lalai", selection: binding(\.mapStyle)) {
                        ForEach([MapLayer.satellite, .standard, .depth, .turbidity], id: \.self) { layer in
                            Text(layer.label).tag(layer)
                        }
                    }
                }

                Section("Bahasa") {
                    Picker("Bahasa", selection: languageBinding) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Tukar bahasa berkuat kuasa serta-merta, tanpa memulakan semula aplikasi.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    NavigationLink("Tentang") { AboutView() }
                    Button("Tamatkan sesi") {
                        dismiss()
                        env.endSession()
                    }
                    .foregroundStyle(Theme.critical)
                }
            }
            .navigationTitle("Tetapan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { settings.appLanguage },
            set: { settings.appLanguage = $0; try? env.context.save() }
        )
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0; try? env.context.save() }
        )
    }
}
