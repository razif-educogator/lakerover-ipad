//
//  CLLocationCoordinate2D+Display.swift
//  LakeRover
//
//  Created by Main Terminal 01 on 17/09/2026.
//

import CoreLocation

extension CLLocationCoordinate2D {
    /// The one coordinate format used across the app: "4.95772, 100.94189".
    /// Five decimals is about a metre of precision — enough to tell two stations apart.
    /// `nonisolated` so the model and service layers can call it too, not just views:
    /// the project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
    nonisolated var displayText: String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }
}
