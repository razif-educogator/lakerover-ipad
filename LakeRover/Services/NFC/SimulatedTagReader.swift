import Foundation

/// Returns the cartridge ID from the demo script after a short, believable delay.
@MainActor
final class SimulatedTagReader: CartridgeTagReader {
    let isAvailable = true
    var expectedTag: String = "C01-A91"

    func readTag() async throws -> String {
        try? await Task.sleep(for: .seconds(1.5))
        return expectedTag
    }
}
