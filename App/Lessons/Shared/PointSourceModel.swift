import Foundation
import Observation

/// Where the target point P comes from: a preset, the probe iPhone in someone's hand,
/// or a frozen copy of either. Positions are in steps in the calibrated world frame.
@Observable
final class PointSourceModel {
  /// One step of travel along a basis direction corresponds to 25 cm of real motion.
  static let metersPerStep = 0.25
  /// At 90° this point's route reads 1.4 a + 0.8 b + 0.3 h.
  static let presetPoint = SIMD3(1.4, 0.3, -0.8)
  /// A few millimeters: physically tiny, but enough to swing coordinates near singularity.
  static let nudgeSteps = 0.006 / metersPerStep

  enum Source {
    case preset, probe, frozen
  }

  private(set) var manualPoint = presetPoint
  private(set) var frozenPoint: SIMD3<Double>?
  /// The position that physical and coordinate changes are measured from.
  private(set) var reference = presetPoint
  private var nudgeSign = 1.0
  private var hasReferenceForProbe = false

  var isFrozen: Bool { frozenPoint != nil }

  /// Converts a probe displacement in meters to steps.
  static func steps(fromMeters meters: SIMD3<Double>?) -> SIMD3<Double>? {
    meters.map { $0 / metersPerStep }
  }

  func source(probe: SIMD3<Double>?) -> Source {
    if frozenPoint != nil { return .frozen }
    return probe == nil ? .preset : .probe
  }

  func point(probe: SIMD3<Double>?) -> SIMD3<Double> {
    frozenPoint ?? probe ?? manualPoint
  }

  /// "I'm leaving the point right here": ignore further probe motion.
  func toggleFreeze(probe: SIMD3<Double>?) {
    if frozenPoint == nil {
      let current = point(probe: probe)
      frozenPoint = current
      reference = current
    } else {
      frozenPoint = nil
      reference = point(probe: probe)
    }
  }

  /// Moves the preset point by a few millimeters, alternating direction.
  func nudge() {
    guard frozenPoint == nil else { return }
    manualPoint.z += Self.nudgeSteps * nudgeSign
    nudgeSign *= -1
  }

  /// Places the preset point within the cross-section, keeping its height along the hinge.
  func setManualCrossSection(_ v: SIMD2<Double>) {
    guard frozenPoint == nil else { return }
    manualPoint.x = v.x
    manualPoint.z = -v.y
    reference = manualPoint
  }

  func markReference(probe: SIMD3<Double>?) {
    reference = point(probe: probe)
  }

  /// Uses the first probe reading as the reference, so changes are measured from where it started.
  func noteProbeReading(_ probe: SIMD3<Double>?) {
    guard let probe, !hasReferenceForProbe, frozenPoint == nil else { return }
    hasReferenceForProbe = true
    reference = probe
  }

  func physicalChange(probe: SIMD3<Double>?) -> SIMD3<Double> {
    point(probe: probe) - reference
  }

  func reset() {
    manualPoint = Self.presetPoint
    frozenPoint = nil
    reference = Self.presetPoint
    nudgeSign = 1
    hasReferenceForProbe = false
  }
}
