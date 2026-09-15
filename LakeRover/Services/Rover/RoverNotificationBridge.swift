import Foundation

/// The only channel between the app and the Reality Composer scene.
/// Identifiers are defined in `docs/reality-composer-contract.md` and are case-sensitive.
@MainActor
enum RoverNotificationBridge {
    static let notifyAction = Notification.Name("RealityKit.NotifyAction")
    static let notificationTrigger = Notification.Name("RealityKit.NotificationTrigger")

    static let identifierKey = "RealityKit.NotifyAction.Identifier"
    static let triggerIdentifierKey = "RealityKit.NotificationTrigger.Identifier"
    static let triggerSceneKey = "RealityKit.NotificationTrigger.Scene"

    /// `true` once the students drop their exported `Rover.reality` into `Resources/`.
    /// Until then the app drives a code-built placeholder with the same object names.
    static var hasRealityFile: Bool {
        Bundle.main.url(forResource: "Rover", withExtension: "reality") != nil
    }

    /// app → model
    static func post(trigger identifier: String, scene: Any? = nil) {
        var userInfo: [String: Any] = [triggerIdentifierKey: identifier]
        if let scene { userInfo[triggerSceneKey] = scene }
        NotificationCenter.default.post(name: notificationTrigger, object: nil, userInfo: userInfo)
    }

    /// model → app. Used by the placeholder to speak the same language as the real file.
    static func post(notify identifier: String) {
        NotificationCenter.default.post(
            name: notifyAction,
            object: nil,
            userInfo: [identifierKey: identifier]
        )
    }

    static func observeNotifyActions(_ handler: @escaping @MainActor (String) -> Void) -> NSObjectProtocol {
        let key = identifierKey
        return NotificationCenter.default.addObserver(
            forName: notifyAction,
            object: nil,
            queue: .main
        ) { note in
            let identifier = note.userInfo?[key] as? String
            MainActor.assumeIsolated {
                if let identifier { handler(identifier) }
            }
        }
    }

    static func observeTriggers(_ handler: @escaping @MainActor (String) -> Void) -> NSObjectProtocol {
        let key = triggerIdentifierKey
        return NotificationCenter.default.addObserver(
            forName: notificationTrigger,
            object: nil,
            queue: .main
        ) { note in
            let identifier = note.userInfo?[key] as? String
            MainActor.assumeIsolated {
                if let identifier { handler(identifier) }
            }
        }
    }

    static func remove(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
