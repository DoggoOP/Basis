import Foundation
import simd

/// Travel instructions for reaching a fixed point with the Duo's directions: c = B⁻¹ p_D.
///
/// The point lives in the room (world frame). The Duo frame can change in two ways:
/// folding changes the basis shape B(α); rotating the whole device changes its
/// orientation R. Either way the point stays put and only its coordinates change.
struct CoordinateSolver {
  var basis: BasisGeometry
  /// The point in the calibrated world frame, in steps.
  var pointWorld: SIMD3<Double>
  /// Rigid rotation of the whole Duo about the vertical hinge axis, in radians.
  var frameYaw: Double = 0
  var originWorld: SIMD3<Double> = .zero

  /// R_DW: world → Duo. The Duo is rotated by +yaw, so the world is seen rotated by −yaw.
  var rotationDuoFromWorld: simd_double3x3 { Self.rotationAboutHinge(-frameYaw) }

  /// The point expressed in the Duo's own axes: p_D = R_DW (p_W − o_W).
  var pointInDuoFrame: SIMD3<Double> { rotationDuoFromWorld * (pointWorld - originWorld) }

  /// Coefficients (c_a, c_b, c_h), or nil when the directions no longer span the space.
  var coefficients: SIMD3<Double>? {
    guard isSolvable else { return nil }
    return basis.B3.inverse * pointInDuoFrame
  }

  /// Coordinate change caused by a physical change Δp at the current frame: B⁻¹ R Δp.
  func coefficientChange(for physicalChange: SIMD3<Double>) -> SIMD3<Double>? {
    guard isSolvable else { return nil }
    return basis.B3.inverse * (rotationDuoFromWorld * physicalChange)
  }

  /// Rebuilds p_D from the coefficients: B c. Used to verify the solve.
  func reconstruct(from coefficients: SIMD3<Double>) -> SIMD3<Double> {
    basis.B3 * coefficients
  }

  private var isSolvable: Bool {
    !basis.isSingular && basis.conditionNumber <= MathTolerance.maximumConditionNumber
  }

  /// Rotation about h = +y.
  static func rotationAboutHinge(_ angle: Double) -> simd_double3x3 {
    let c = cos(angle), s = sin(angle)
    return simd_double3x3(columns: (SIMD3(c, 0, -s), SIMD3(0, 1, 0), SIMD3(s, 0, c)))
  }
}
