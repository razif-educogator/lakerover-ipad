import Foundation

@MainActor
protocol CartridgeTagReader: AnyObject {
    var isAvailable: Bool { get }
    /// The ID the reader should return next in demo mode.
    var expectedTag: String { get set }
    func readTag() async throws -> String
}

enum TagReaderError: LocalizedError {
    case unavailable
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unavailable: "Pembaca NFC tidak tersedia pada peranti ini."
        case .cancelled: "Bacaan tag dibatalkan."
        }
    }
}
