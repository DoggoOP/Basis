import CoreMotion
import Foundation
import Observation
import simd
import UIKit

/// Rigid rotation of the whole Duo about the vertical (hinge) axis.
///
/// Folding changes the basis shape; rotating changes its orientation. On iOS 27, a `UIView`
/// can be the `deviceMotionBody`, so the attitude refers to the panel that view sits on
/// (panel A, the frame's reference). When no motion data arrives (for example if a
/// simulator doesn't supply it) an explicitly labeled demo control stands in, and the UI
/// never calls that sensed.
@Observable
final class DuoAttitudeProvider {
  enum Source: Equatable {
    /// Device motion reports it is available; waiting for the first sample.
    case waitingForSensor
    /// Samples are arriving from CoreMotion.
    case continuousSensor
    /// No device motion here; the on-screen control drives the rotation.
    case simulatedControl
  }

  private(set) var source: Source
  /// Yaw relative to the reference pose, in degrees.
  private(set) var yawDegrees = 0.0

  // Diagnostics for the Calibration screen.
  private(set) var isDeviceMotionAvailable: Bool
  private(set) var sampleCount = 0
  private(set) var rawYawPitchRoll: SIMD3<Double>?
  private(set) var rawQuaternion: simd_quatd?
  private(set) var usesPanelBody = false
  private(set) var isRunning = false

  @ObservationIgnored private let motion = CMMotionManager()
  @ObservationIgnored private var referenceHeading: Double?
  @ObservationIgnored private weak var body: UIView?
  @ObservationIgnored private var fallbackTask: Task<Void, Never>?

  /// How long to wait for a first sample before offering the demo control.
  private static let sensorTimeout: Duration = .seconds(2)

  init() {
    let available = CMMotionManager().isDeviceMotionAvailable
    isDeviceMotionAvailable = available
    source = available ? .waitingForSensor : .simulatedControl
  }

  var yawRadians: Double { yawDegrees.degreesToRadians }

  var isSensed: Bool { source == .continuousSensor }

  /// iOS 27.2 reports whether the app may read motion data.
  var authorizationDescription: String {
    #if canImport(CoreMotion, _version: 3186)
    if #available(iOS 27.2, *) {
      switch CMMotionManager.authorizationStatus() {
      case .authorized: return "Authorized"
      case .denied: return "Denied"
      case .restricted: return "Restricted"
      case .notDetermined: return "Not determined"
      @unknown default: return "Unknown"
      }
    }
    #endif
    return "Not reported before iOS 27.2"
  }

  /// Drives the yaw from the on-screen control when no sensor is available.
  var simulatedYawDegrees: Double {
    get { yawDegrees }
    set {
      guard source == .simulatedControl else { return }
      yawDegrees = min(max(newValue, -90), 90)
    }
  }

  /// The view whose panel defines the Duo frame. Set before or after `start()`.
  func setBody(_ view: UIView?) {
    body = view
    if #available(iOS 27.0, *) {
      motion.deviceMotionBody = view
      usesPanelBody = view != nil
    }
  }

  func start() {
    guard isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
    if #available(iOS 27.0, *), let body { motion.deviceMotionBody = body }
    motion.deviceMotionUpdateInterval = 1.0 / 30
    isRunning = true
    motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
      guard let self, let data else { return }
      self.receive(data.attitude)
    }
    // If the hardware claims motion but never delivers it, hand over to the demo control.
    fallbackTask?.cancel()
    fallbackTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: Self.sensorTimeout)
      guard let self, !Task.isCancelled, self.sampleCount == 0 else { return }
      self.source = .simulatedControl
    }
  }

  func stop() {
    motion.stopDeviceMotionUpdates()
    fallbackTask?.cancel()
    isRunning = false
  }

  /// Makes the current pose the unrotated reference frame.
  func resetReference() {
    referenceHeading = nil
    if source != .continuousSensor { yawDegrees = 0 }
  }

  private func receive(_ attitude: CMAttitude) {
    sampleCount += 1
    source = .continuousSensor
    let q = attitude.quaternion
    let rotation = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
    rawQuaternion = rotation
    rawYawPitchRoll = SIMD3(attitude.yaw, attitude.pitch, attitude.roll).map(\.radiansToDegrees)
    let heading = Self.heading(of: rotation)
    if referenceHeading == nil { referenceHeading = heading }
    yawDegrees = Self.wrapped(heading - (referenceHeading ?? heading))
  }

  /// Heading of the body's screen normal projected onto the horizontal plane (z is vertical).
  /// Works while the device stands upright like a book, where Euler yaw is ill-defined.
  private static func heading(of rotation: simd_quatd) -> Double {
    let normal = rotation.act(SIMD3(0, 0, 1))
    return atan2(normal.y, normal.x).radiansToDegrees
  }

  private static func wrapped(_ degrees: Double) -> Double {
    var d = degrees.truncatingRemainder(dividingBy: 360)
    if d > 180 { d -= 360 }
    if d <= -180 { d += 360 }
    return d
  }
}

private extension SIMD3 where Scalar == Double {
  func map(_ transform: (Double) -> Double) -> SIMD3<Double> {
    SIMD3(transform(x), transform(y), transform(z))
  }
}
