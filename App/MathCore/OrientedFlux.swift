import Foundation

/// Flux of a uniform field through panel B, whose two faces are the inner and outer displays.
///
/// The field F is fixed to panel A: it points along panel A's inner normal n_A with
/// strength |F|. Panel B has unit area, so Φ_n = F · n_B. The outer face of the same
/// slab has normal −n_B, so its flux is exactly the negative.
struct OrientedFlux {
  static let fieldStrength = 5.0

  var openingDegrees: Double

  private var geometry: FoldGeometry { FoldGeometry(openingDegrees: openingDegrees) }

  var field: SIMD3<Double> { geometry.normalA * Self.fieldStrength }

  /// Φ_n = F · n (inner face).
  var innerFlux: Double { MathTolerance.exact(geometry.normalA.dot(geometry.normalB)) * Self.fieldStrength }

  /// Φ_{−n} = F · (−n) = −Φ_n (outer face).
  var outerFlux: Double { -innerFlux }
}
