import CoreLocation
import Foundation

/// Small flat-earth helpers — good enough for a 500 m lake.
enum Geo {
    static let metresPerDegreeLat: Double = 111_132

    static func metresPerDegreeLon(atLatitude lat: Double) -> Double {
        111_320 * cos(lat * .pi / 180)
    }

    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dy = (b.latitude - a.latitude) * metresPerDegreeLat
        let dx = (b.longitude - a.longitude) * metresPerDegreeLon(atLatitude: a.latitude)
        return (dx * dx + dy * dy).squareRoot()
    }

    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let dy = (b.latitude - a.latitude) * metresPerDegreeLat
        let dx = (b.longitude - a.longitude) * metresPerDegreeLon(atLatitude: a.latitude)
        let deg = atan2(dx, dy) * 180 / .pi
        return deg < 0 ? deg + 360 : deg
    }

    static func interpolate(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, fraction t: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }
}

/// Deterministic pseudo-random source so the demo run is repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64 = 0x4C616B65_526F7665) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Symmetric noise in ±amount.
    mutating func noise(_ amount: Double) -> Double {
        Double.random(in: -amount...amount, using: &self)
    }
}
