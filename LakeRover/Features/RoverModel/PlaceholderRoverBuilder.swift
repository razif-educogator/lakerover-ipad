#if canImport(RealityKit)
import RealityKit
import UIKit
import simd

/// Stands in for `Resources/Rover.reality` until the students export theirs from
/// Reality Composer on iPad. Same object names as the contract, so dropping the real file
/// into `Resources/` replaces this with no code change.
@MainActor
enum PlaceholderRoverBuilder {
    static func make() -> Entity {
        let root = Entity()
        root.name = "Rover"

        root.addChild(box(name: "Badan", size: [0.42, 0.07, 0.24], position: [0, 0.035, 0], hue: 0.55))
        root.addChild(box(name: "PanelSolar", size: [0.26, 0.012, 0.16], position: [0, 0.078, 0], hue: 0.12))
        root.addChild(box(name: "AntenaGPS", size: [0.012, 0.14, 0.012], position: [-0.08, 0.15, 0], hue: 0.7))
        root.addChild(box(name: "Kamera360", size: [0.04, 0.04, 0.04], position: [0.09, 0.11, 0], hue: 0.02))
        root.addChild(box(name: "Pendorong", size: [0.06, 0.05, 0.05], position: [-0.22, 0.02, 0], hue: 0.33))
        root.addChild(box(name: "Pam", size: [0.05, 0.05, 0.05], position: [0.05, 0.02, 0.09], hue: 0.85))
        root.addChild(box(name: "Kartrij", size: [0.035, 0.06, 0.035], position: [0.0, 0.02, 0.09], hue: 0.6))
        root.addChild(box(name: "Botol", size: [0.05, 0.08, 0.05], position: [-0.06, 0.03, 0.09], hue: 0.48))

        // "Pensampel" groups the sampling chain so the contract's show/hide works.
        let sampler = Entity()
        sampler.name = "Pensampel"
        root.addChild(sampler)

        return root
    }

    /// Entity names that belong to each group trigger.
    static func names(for group: RoverGroup) -> Set<String> {
        switch group {
        case .showAll:
            ["Badan", "PanelSolar", "AntenaGPS", "Kamera360", "Pendorong", "Pam", "Kartrij", "Botol", "Pensampel"]
        case .showPensampel:
            ["Badan", "Pam", "Kartrij", "Botol", "Pensampel"]
        case .showElektronik:
            ["Badan", "AntenaGPS", "Kamera360", "PanelSolar"]
        case .showPropulsi:
            ["Badan", "Pendorong"]
        }
    }

    /// Maps a tapped entity back to a contract identifier.
    static func component(forEntityNamed name: String) -> RoverComponent? {
        RoverComponent.allCases.first {
            $0.entityName == name || samplingChain.contains(name) && $0 == .pensampel
        }
    }

    private static let samplingChain: Set<String> = ["Pam", "Kartrij", "Botol", "Pensampel"]

    private static func box(name: String, size: SIMD3<Float>, position: SIMD3<Float>, hue: Double) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.004)
        var material = SimpleMaterial()
        material.color = .init(tint: color(hue: hue))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        entity.position = position
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    private static func color(hue: Double) -> UIColor {
        UIColor(hue: hue, saturation: 0.55, brightness: 0.85, alpha: 1)
    }
}
#endif
