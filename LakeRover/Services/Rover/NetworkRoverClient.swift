import Foundation

/// Real rover link over the local Wi-Fi / 4G WebSocket. Fully typed but stubbed in v1:
/// `connect()` throws so the app always falls back to demo mode.
@MainActor
final class NetworkRoverClient: RoverClient {
    let isDemo = false
    var speedMultiplier: Double = 1

    private let endpoint: URL
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Telemetry>.Continuation?

    init(endpoint: URL = URL(string: "ws://lakerover.local:8080/telemetry")!) {
        self.endpoint = endpoint
    }

    func connect() async throws {
        guard FeatureFlags.networkRoverEnabled else { throw RoverError.notAvailable }
        task = URLSession.shared.webSocketTask(with: endpoint)
        task?.resume()
        receiveLoop()
    }

    func telemetry() -> AsyncStream<Telemetry> {
        AsyncStream(bufferingPolicy: .bufferingNewest(4)) { continuation in
            self.continuation = continuation
        }
    }

    func send(_ command: RoverCommand) async throws {
        guard let task else { throw RoverError.notAvailable }
        let payload = CommandEnvelope(command)
        let data = try JSONEncoder().encode(payload)
        try await task.send(.data(data))
    }

    // MARK: - Wire format

    /// `{ "type": "telemetry", "lat": …, "lon": …, "battery": … }`
    private nonisolated struct TelemetryEnvelope: Decodable {
        var type: String
        var lat: Double
        var lon: Double
        var heading: Double
        var speed: Double
        var battery: Int
        var solar: Double
        var link: Int
    }

    /// `{ "type": "command", "name": "start", "value": … }`
    private nonisolated struct CommandEnvelope: Encodable {
        var type = "command"
        var name: String
        var value: String?

        init(_ command: RoverCommand) {
            switch command {
            case .start: name = "start"
            case .pause: name = "pause"
            case .resume: name = "resume"
            case .emergencyStop: name = "emergency_stop"
            case .resumeAfterStop: name = "resume_after_stop"
            case .returnHome: name = "return_home"
            case .stopSampling: name = "stop_sampling"
            case .restartSampling: name = "restart_sampling"
            case .loadRoute: name = "load_route"
            case .skipStation(let i): name = "skip_station"; value = String(i)
            case .startSampling(let i, _): name = "start_sampling"; value = String(i)
            case .setAutoReturn(let on, let pct): name = "set_auto_return"; value = "\(on):\(pct)"
            case .setAutonomous(let on): name = "set_autonomous"; value = String(on)
            case .setPowerSave(let on): name = "set_power_save"; value = String(on)
            case .demoSkipTo: name = "noop"
            }
        }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            if case .success(.data(let data)) = result,
               let frame = try? JSONDecoder().decode(TelemetryEnvelope.self, from: data),
               frame.type == "telemetry" {
                var t = Telemetry()
                t.latitude = frame.lat
                t.longitude = frame.lon
                t.headingDeg = frame.heading
                t.speedMps = frame.speed
                t.batteryPct = frame.battery
                t.solarW = frame.solar
                t.linkQuality = frame.link
                Task { @MainActor in self.continuation?.yield(t) }
            }
            Task { @MainActor in self.receiveLoop() }
        }
    }
}
