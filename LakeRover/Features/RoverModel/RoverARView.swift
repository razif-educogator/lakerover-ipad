#if canImport(ARKit) && canImport(RealityKit)
import ARKit
import RealityKit
import SwiftUI

/// Loads `Rover.reality` into an `ARView` and exchanges notifications with it (R5.1–R5.6).
/// No 3D logic lives here beyond anchoring and the tap → identifier mapping.
struct RoverARView: UIViewRepresentable {
    var model: RoverModelViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)

        if FeatureFlags.arEnabled, ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            view.session.run(configuration)
            context.coordinator.addCoaching(to: view)
        } else {
            // R5.6 fallback on hardware without world tracking.
            view.cameraMode = .nonAR
            view.environment.background = .color(.systemGray5)
        }

        let anchor: AnchorEntity = FeatureFlags.arEnabled
            ? AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.2, 0.2]))
            : AnchorEntity(world: .zero)

        let rover = context.coordinator.loadRover()
        anchor.addChild(rover)
        view.scene.addAnchor(anchor)
        context.coordinator.rover = rover
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.apply(group: model.group, realScale: model.realScale)
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.detach()
        view.session.pause()
    }

    @MainActor
    final class Coordinator: NSObject {
        private let model: RoverModelViewModel
        var rover: Entity?
        private var triggerObserver: NSObjectProtocol?
        private weak var view: ARView?

        init(model: RoverModelViewModel) {
            self.model = model
        }

        func loadRover() -> Entity {
            if let entity = try? Entity.load(named: "Rover") {
                return entity
            }
            return PlaceholderRoverBuilder.make()
        }

        func attach(to view: ARView) {
            self.view = view
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            view.addGestureRecognizer(tap)

            // The real Reality file responds to these itself; the placeholder needs help.
            guard !RoverNotificationBridge.hasRealityFile else { return }
            triggerObserver = RoverNotificationBridge.observeTriggers { [weak self] identifier in
                guard let self else { return }
                if let group = RoverGroup(rawValue: identifier) {
                    self.apply(group: group, realScale: self.model.realScale)
                } else if identifier == RoverTrigger.scaleReal.rawValue {
                    self.apply(group: self.model.group, realScale: true)
                } else if identifier == RoverTrigger.scaleTabletop.rawValue {
                    self.apply(group: self.model.group, realScale: false)
                }
            }
        }

        func detach() {
            if let triggerObserver { RoverNotificationBridge.remove(triggerObserver) }
            triggerObserver = nil
        }

        func addCoaching(to view: ARView) {
            let coaching = ARCoachingOverlayView()
            coaching.session = view.session
            coaching.goal = .horizontalPlane
            coaching.activatesAutomatically = true
            coaching.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(coaching)
            NSLayoutConstraint.activate([
                coaching.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                coaching.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                coaching.topAnchor.constraint(equalTo: view.topAnchor),
                coaching.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        func apply(group: RoverGroup, realScale: Bool) {
            guard let rover, !RoverNotificationBridge.hasRealityFile else { return }
            let visible = PlaceholderRoverBuilder.names(for: group)
            for child in rover.children {
                child.isEnabled = visible.contains(child.name)
            }
            rover.scale = realScale ? .one : SIMD3<Float>(repeating: 0.2)
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, let entity = view.entity(at: gesture.location(in: view)) else { return }
            // The real file posts this itself; keep parity for the placeholder.
            guard !RoverNotificationBridge.hasRealityFile else { return }
            if let component = PlaceholderRoverBuilder.component(forEntityNamed: entity.name) {
                RoverNotificationBridge.post(notify: component.rawValue)
            }
        }
    }
}
#endif
