import Foundation

/// Physical geometry of the two inner-display panels, symmetric about the viewer.
///
/// World frame: x points right across the flat display, y points up along the
/// hinge (h), z points out of the flat display toward the viewer. α is the physical
/// opening angle: 0° closed, 180° flat. Used for the top-down fold diagrams.
struct FoldGeometry {
  var openingDegrees: Double

  var alpha: Double { openingDegrees.degreesToRadians }

  /// Unit vector in panel A, perpendicular to the hinge, pointing away from it.
  var a: SIMD3<Double> { SIMD3(-sin(alpha / 2), 0, cos(alpha / 2)) }

  /// Unit vector in panel B, perpendicular to the hinge, pointing away from it.
  var b: SIMD3<Double> { SIMD3(sin(alpha / 2), 0, cos(alpha / 2)) }

  /// Unit normal of panel A's display, facing into the fold.
  var normalA: SIMD3<Double> { SIMD3(cos(alpha / 2), 0, sin(alpha / 2)) }

  /// Unit normal of panel B's display, facing into the fold.
  var normalB: SIMD3<Double> { SIMD3(-cos(alpha / 2), 0, sin(alpha / 2)) }

  /// Angle between the two display normals: θ = π − α.
  var normalAngleDegrees: Double { 180 - openingDegrees }
}

extension SIMD3 where Scalar == Double {
  func dot(_ other: Self) -> Double { (self * other).sum() }

  func cross(_ other: Self) -> Self {
    SIMD3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x
    )
  }

  var length: Double { dot(self).squareRoot() }
}

extension SIMD2 where Scalar == Double {
  func dot(_ other: Self) -> Double { (self * other).sum() }
  var length: Double { dot(self).squareRoot() }
}
