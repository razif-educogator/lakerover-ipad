import Foundation

/// The only thing the UI knows about the rover. Demo mode swaps the implementation.
@MainActor
protocol RoverClient: AnyObject {
    var isDemo: Bool { get }
    /// 1× for a live mission, 5× for rehearsal and Showcase mode.
    var speedMultiplier: Double { get set }

    func connect() async throws
    func telemetry() -> AsyncStream<Telemetry>
    func send(_ command: RoverCommand) async throws
}
