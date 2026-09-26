import Foundation

/// The tiny payload streamed from the probe iPhone: a calibrated displacement in meters.
struct ProbePacket: Codable, Equatable {
  enum Quality: String, Codable {
    case normal, limited, unavailable
  }

  var x: Double
  var y: Double
  var z: Double
  /// Probe orientation relative to its origin, for debugging only.
  var qx: Double = 0
  var qy: Double = 0
  var qz: Double = 0
  var qw: Double = 1
  var quality: Quality
  var timestamp: TimeInterval

  enum CodingKeys: String, CodingKey {
    case x, y, z, qx, qy, qz, qw, timestamp
    case quality = "tracking"
  }

  var vector: SIMD3<Double> { SIMD3(x, y, z) }
}

enum PeerConfiguration {
  /// Bonjour service type; must match NSBonjourServices in Info.plist.
  static let serviceType = "basis-probe"
  /// Target update rate for the probe stream.
  static let packetInterval: TimeInterval = 1.0 / 15
}
