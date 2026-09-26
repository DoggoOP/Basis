import Foundation
import Observation

/// Where the fixed physical vector p comes from, and what it is compared against.
@Observable
final class ChangeOfBasisModel {
  /// Demo preset in meters: at 90° its coordinates read (+0.42, +0.31, +0.18).
  static let presetVector = SIMD3(0.42, 0.18, 0.31)
  /// A few millimeters: enough to be physically tiny, enough to swing coordinates near singularity.
  static let nudgeDistance = 0.006

  enum Source {
    case preset, probe, frozen
  }

  private(set) var manualVector = presetVector
  private(set) var frozenVector: SIMD3<Double>?
  /// The position that physical and coordinate changes are measured from.
  private(set) var reference = presetVector
  private var nudgeSign = 1.0
  private var hasReferenceForProbe = false

  var isFrozen: Bool { frozenVector != nil }

  func source(probe: SIMD3<Double>?) -> Source {
    if frozenVector != nil { return .frozen }
    return probe == nil ? .preset : .probe
  }

  func vector(probe: SIMD3<Double>?) -> SIMD3<Double> {
    frozenVector ?? probe ?? manualVector
  }

  /// Captures the live vector and ignores further motion, so the presenter can set the probe down.
  func toggleFreeze(probe: SIMD3<Double>?) {
    if frozenVector == nil {
      let current = vector(probe: probe)
      frozenVector = current
      reference = current
    } else {
      frozenVector = nil
      reference = vector(probe: probe)
    }
  }

  /// Moves the preset vector by a few millimeters, alternating direction.
  func nudge() {
    guard frozenVector == nil else { return }
    manualVector.z += Self.nudgeDistance * nudgeSign
    nudgeSign *= -1
  }

  /// Drags the preset vector within the cross-section (x and z).
  func setManualCrossSection(x: Double, z: Double) {
    guard frozenVector == nil else { return }
    manualVector.x = x
    manualVector.z = z
    reference = manualVector
  }

  func markReference(probe: SIMD3<Double>?) {
    reference = vector(probe: probe)
  }

  /// Uses the first probe reading as the reference, so changes are measured from where it started.
  func noteProbeReading(_ probe: SIMD3<Double>?) {
    guard let probe, !hasReferenceForProbe, frozenVector == nil else { return }
    hasReferenceForProbe = true
    reference = probe
  }

  func physicalChange(probe: SIMD3<Double>?) -> SIMD3<Double> {
    vector(probe: probe) - reference
  }

  func reset() {
    manualVector = Self.presetVector
    frozenVector = nil
    reference = Self.presetVector
    nudgeSign = 1
    hasReferenceForProbe = false
  }
}
