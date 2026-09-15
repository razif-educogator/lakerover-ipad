import Foundation
import Observation

/// Talks to the Reality Composer scene through notifications only (R5.7).
/// When no `Rover.reality` is bundled it also plays the *model's* side of the contract, so
/// the sampling demo and the group chips behave the same in the Simulator.
@MainActor
@Observable
final class RoverModelViewModel {
    var group: RoverGroup = .showAll
    var realScale = false
    var selected: RoverComponent?
    var samplingStep: SamplingPhase?
    var isPlayingSampling = false

    private var notifyObserver: NSObjectProtocol?
    private var playbackTask: Task<Void, Never>?

    var usingPlaceholder: Bool { !RoverNotificationBridge.hasRealityFile }

    func start() {
        guard notifyObserver == nil else { return }
        notifyObserver = RoverNotificationBridge.observeNotifyActions { [weak self] identifier in
            self?.handle(identifier)
        }
        RoverNotificationBridge.post(trigger: RoverGroup.showAll.rawValue)
    }

    func stop() {
        if let notifyObserver { RoverNotificationBridge.remove(notifyObserver) }
        notifyObserver = nil
        playbackTask?.cancel()
        playbackTask = nil
        isPlayingSampling = false
    }

    /// model → app
    func handle(_ identifier: String) {
        if let component = RoverComponent(rawValue: identifier) {
            selected = component
            return
        }
        if let phase = SamplingPhase(notificationIdentifier: identifier) {
            samplingStep = phase
            if phase == .move {
                isPlayingSampling = false
            }
        }
    }

    // MARK: app → model

    func select(_ group: RoverGroup) {
        self.group = group
        selected = nil
        RoverNotificationBridge.post(trigger: group.rawValue)
    }

    func tap(_ component: RoverComponent) {
        // Stand-in for the scene's own Tap → Emphasize → Notify behaviour.
        RoverNotificationBridge.post(notify: component.rawValue)
    }

    func toggleScale() {
        realScale.toggle()
        RoverNotificationBridge.post(
            trigger: (realScale ? RoverTrigger.scaleReal : RoverTrigger.scaleTabletop).rawValue
        )
    }

    /// R5.4 — "Main demo pensampelan": the scene animates and reports each step back.
    func playSampling() {
        guard !isPlayingSampling else { return }
        isPlayingSampling = true
        samplingStep = nil
        select(.showPensampel)
        RoverNotificationBridge.post(trigger: RoverTrigger.playSampling.rawValue)

        guard usingPlaceholder else { return }
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            for phase in SamplingPhase.allCases {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled else { return }
                guard self != nil else { return }
                RoverNotificationBridge.post(notify: phase.notificationIdentifier)
            }
        }
    }
}
