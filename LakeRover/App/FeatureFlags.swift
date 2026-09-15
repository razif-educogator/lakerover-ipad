import Foundation

/// Compile/run-time switches for the demo build.
enum FeatureFlags {
    /// `false` on the Simulator: the AR camera is unavailable there, so the Rover Model
    /// screen falls back to the non-AR diagram. Only the camera choice depends on this.
    static var arEnabled: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    /// The real rover link is stubbed in v1 — the app always runs the simulated client.
    static let networkRoverEnabled = false

    /// Core NFC needs an entitlement and real hardware; the demo uses the simulated reader.
    static var nfcEnabled: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return false
        #endif
    }

    /// Hidden rehearsal speed for the demo mission.
    static let showcaseSpeedMultiplier: Double = 5
}
