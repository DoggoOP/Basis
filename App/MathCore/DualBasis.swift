import Foundation
import simd

/// The dual basis of the 2D cross-section: the rows of B⁻¹.
///
/// A basis tells you how to build a vector; the dual basis tells you how to measure one.
/// ω¹ reads the a-coefficient and ω² reads the b-coefficient, with ωⁱ(e_j) = δⁱ_j.
struct DualBasis {
  var basis: BasisGeometry

  /// B⁻¹ = [[1, −cot α], [0, csc α]], or nil when singular.
  var inverse: simd_double2x2? {
    basis.isSingular ? nil : basis.B2.inverse
  }

  /// First row of B⁻¹: measures the a-coefficient.
  var omega1: SIMD2<Double>? {
    inverse.map { SIMD2($0[0][0], $0[1][0]) }
  }

  /// Second row of B⁻¹: measures the b-coefficient.
  var omega2: SIMD2<Double>? {
    inverse.map { SIMD2($0[0][1], $0[1][1]) }
  }

  /// ωⁱ(e_j) for i, j ∈ {1, 2}; the identity whenever the dual basis exists.
  var pairing: [[Double]]? {
    guard let omega1, let omega2 else { return nil }
    let e = [basis.a2, basis.b2]
    return [omega1, omega2].map { w in e.map { MathTolerance.exact(w.dot($0)) } }
  }

  /// Measures a vector: (ω¹(p), ω²(p)).
  func measure(_ p: SIMD2<Double>) -> SIMD2<Double>? {
    guard let omega1, let omega2 else { return nil }
    return SIMD2(omega1.dot(p), omega2.dot(p))
  }
}
