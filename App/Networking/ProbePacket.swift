import Foundation

/// The tiny payload streamed from the probe iPhone: a calibrated displacement in meters.
struct ProbePacket: Codable, Equatable {
  enum Quality: String, Codable {
    case normal, limited, unavailable
  }

  var x: Double
  var y: Double
  var z: Double
  var quality: Quality
  var timestamp: TimeInterval

  var vector: SIMD3<Double> { SIMD3(x, y, z) }
}

enum PeerConfiguration {
  /// Bonjour service type; must match NSBonjourServices in Info.plist.
  static let serviceType = "basis-probe"
  /// Target update rate for the probe stream.
  static let packetInterval: TimeInterval = 1.0 / 30
}
