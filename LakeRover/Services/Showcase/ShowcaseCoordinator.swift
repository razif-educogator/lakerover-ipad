import Foundation
import Observation

/// The three-minute judge tour: Live Map → Sampling → AR model → Insights.
/// Started by a long-press on the Splash logo. Drives the router; owns no views.
@MainActor
@Observable
final class ShowcaseCoordinator {
    struct Step: Identifiable, Sendable {
        var id: Int
        var titleMS: String
        var titleEN: String
        var captionMS: String
        var captionEN: String
    }

    static let steps: [Step] = [
        Step(
            id: 0,
            titleMS: "Pantau",
            titleEN: "Track",
            captionMS: "Rover bergerak sendiri di Tasik Cenderoh — kedudukan, bateri dan pautan masa nyata.",
            captionEN: "The rover runs itself on Tasik Cenderoh — live position, battery and link."
        ),
        Step(
            id: 1,
            titleMS: "Sampel",
            titleEN: "Sample",
            captionMS: "Enam langkah di setiap stesen: pam, kartrij, tag RFID, simpan — semuanya boleh dipantau.",
            captionEN: "Six steps at every station: pump, cartridge, RFID tag, store — all visible."
        ),
        Step(
            id: 2,
            titleMS: "Model",
            titleEN: "Model",
            captionMS: "Model rover dibina pelajar dalam Reality Composer — ketik komponen untuk penerangan.",
            captionEN: "Students built the rover in Reality Composer — tap a part for its story."
        ),
        Step(
            id: 3,
            titleMS: "Tindakan",
            titleEN: "Action",
            captionMS: "Dari data ke tindakan: trend, peta haba dan cadangan tindakan sedia dikongsi.",
            captionEN: "From data to action: trend, heat map and a recommendation ready to share."
        )
    ]

    private(set) var isActive = false
    private(set) var stepIndex = 0

    var step: Step { Self.steps[min(stepIndex, Self.steps.count - 1)] }
    var isLastStep: Bool { stepIndex >= Self.steps.count - 1 }

    func start(env: AppEnvironment) {
        isActive = true
        stepIndex = 0
        env.startShowcaseSession()
        apply(env: env)
    }

    func next(env: AppEnvironment) {
        guard isActive else { return }
        if isLastStep {
            exit(env: env)
        } else {
            stepIndex += 1
            apply(env: env)
        }
    }

    func exit(env: AppEnvironment) {
        isActive = false
        stepIndex = 0
        env.client.speedMultiplier = 1
        env.router.go(.live)
    }

    private func apply(env: AppEnvironment) {
        switch stepIndex {
        case 0:
            env.router.go(.live)
        case 1:
            // Jump the simulation to station 2 so sampling is on screen immediately.
            env.runtime.fastForward(to: 1)
            env.send(.demoSkipTo(stationIndex: 1))
            env.router.pushMission(.sampling)
        case 2:
            env.router.pushMission(.roverModel)
        default:
            // Close the loop: a full set of readings, the attention card and the PDF.
            env.runtime.fillDemoSamples()
            env.router.go(.data)
        }
    }
}
