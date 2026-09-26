import Foundation
import simd

/// Coordinates of a fixed physical vector in the Duo basis: c = B⁻¹ p.
struct ChangeOfBasis {
  var basis: BasisGeometry
  /// The physical vector, in meters, in the canonical frame.
  var vector: SIMD3<Double>

  /// Coefficients (c_a, c_b, c_h), or nil when the basis has collapsed.
  var coefficients: SIMD3<Double>? {
    guard isSolvable else { return nil }
    return basis.B3.inverse * vector
  }

  /// Coordinate change caused by a physical change Δp at the current basis: B⁻¹ Δp.
  func coefficientChange(for physicalChange: SIMD3<Double>) -> SIMD3<Double>? {
    guard isSolvable else { return nil }
    return basis.B3.inverse * physicalChange
  }

  /// Rebuilds p from the coefficients: B c. Used to verify the solve.
  func reconstruct(from coefficients: SIMD3<Double>) -> SIMD3<Double> {
    basis.B3 * coefficients
  }

  private var isSolvable: Bool {
    !basis.isSingular && basis.conditionNumber <= MathTolerance.maximumConditionNumber
  }
}
