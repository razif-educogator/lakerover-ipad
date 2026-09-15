import Foundation

/// Core NFC reader. Stubbed in v1: Core NFC needs an entitlement and real hardware, so the
/// Tag step always falls back to the simulated reader or manual entry.
@MainActor
final class NFCCartridgeTagReader: CartridgeTagReader {
    var isAvailable: Bool { FeatureFlags.nfcEnabled }
    var expectedTag: String = ""

    func readTag() async throws -> String {
        // Real implementation: NFCTagReaderSession(pollingOption: .iso14443) → read the
        // NDEF payload → return the cartridge ID string.
        throw TagReaderError.unavailable
    }
}
