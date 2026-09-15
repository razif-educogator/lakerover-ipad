import Foundation
import Observation

/// Owns the cartridge-tag step and the Hentikan / Ulang behaviour.
@MainActor
@Observable
final class SamplingViewModel {
    var tagID: String?
    var isScanning = false
    var showManualEntry = false
    var manualTag = ""
    var tagMessage: String?

    private var scannedStationIndex: Int?

    /// Called on every telemetry frame; kicks off the tag read once the Tag step is reached.
    func sync(with sampling: SamplingTelemetry?, reader: any CartridgeTagReader) {
        guard let sampling else { return }
        if scannedStationIndex != sampling.stationIndex {
            scannedStationIndex = sampling.stationIndex
            tagID = nil
            tagMessage = nil
        }
        guard sampling.phase >= .tag, tagID == nil, !isScanning else { return }
        readTag(reader: reader, expected: sampling.cartridgeID)
    }

    func readTag(reader: any CartridgeTagReader, expected: String) {
        isScanning = true
        tagMessage = String(localized: "Mengimbas tag kartrij…")
        reader.expectedTag = expected
        Task { [weak self] in
            guard let self else { return }
            do {
                let id = try await reader.readTag()
                self.tagID = id
                self.tagMessage = nil
            } catch {
                // NFC unavailable — offer manual entry (design.md, error handling).
                self.tagMessage = String(localized: "Pembaca NFC tidak tersedia.")
                self.showManualEntry = true
            }
            self.isScanning = false
        }
    }

    func applyManualTag() {
        let trimmed = manualTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tagID = trimmed
        tagMessage = nil
        showManualEntry = false
        manualTag = ""
    }

    func reset() {
        tagID = nil
        isScanning = false
        tagMessage = nil
        scannedStationIndex = nil
    }
}
