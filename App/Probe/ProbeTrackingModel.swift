import ARKit
import Foundation
import Observation
import simd

/// Headless ARKit world tracking: no camera view, just the device's calibrated displacement.
@Observable
final class ProbeTrackingModel: NSObject {
  enum Tracking: Equatable {
    case starting, good, moveSlowly, unsupported
  }

  /// Light low-pass filter so the display is clean but the response stays immediate.
  private static let smoothing = 0.5

  private(set) var tracking = Tracking.starting
  /// Displacement from the origin in the canonical frame, meters.
  private(set) var position: SIMD3<Double>?

  @ObservationIgnored private let session = ARSession()
  @ObservationIgnored private var calibration: ProbeCalibration?
  @ObservationIgnored private var needsRecenter = true
  @ObservationIgnored var onUpdate: ((ProbePacket) -> Void)?

  var isSupported: Bool { ARWorldTrackingConfiguration.isSupported }

  func start() {
    guard isSupported else {
      tracking = .unsupported
      return
    }
    let configuration = ARWorldTrackingConfiguration()
    configuration.worldAlignment = .gravity
    session.delegate = self
    session.run(configuration, options: [.resetTracking])
  }

  func stop() { session.pause() }

  /// SET ORIGIN: makes the current pose the origin of the shared frame.
  func setOrigin() { needsRecenter = true }

  private var quality: ProbePacket.Quality {
    switch tracking {
    case .good: .normal
    case .moveSlowly: .limited
    case .starting, .unsupported: .unavailable
    }
  }
}

extension ProbeTrackingModel: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    switch frame.camera.trackingState {
    case .normal: tracking = .good
    case .limited: tracking = .moveSlowly
    case .notAvailable: tracking = .starting
    }
    let transform = frame.camera.transform
    if needsRecenter, tracking == .good {
      calibration = ProbeCalibration(origin: transform)
      needsRecenter = false
    }
    guard let calibration else { return }
    let raw = calibration.displacement(of: transform)
    let filtered = position.map { $0 + (raw - $0) * Self.smoothing } ?? raw
    position = filtered
    let q = calibration.relativeRotation(of: transform)
    onUpdate?(ProbePacket(
      x: filtered.x, y: filtered.y, z: filtered.z,
      qx: q.imag.x, qy: q.imag.y, qz: q.imag.z, qw: q.real,
      quality: quality, timestamp: frame.timestamp
    ))
  }
}
