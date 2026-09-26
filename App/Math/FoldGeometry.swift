import Foundation

/// Physical geometry of the two inner-display panels for a given opening angle.
///
/// World frame: x points right across the flat display, y points up along the
/// hinge (the hinge direction h), z points out of the flat display toward the viewer.
/// α is the physical opening angle: 0° closed, 180° flat.
struct FoldGeometry {
  var openingDegrees: Double

  var alpha: Double { openingDegrees * .pi / 180 }

  /// Unit vector in the leading panel, perpendicular to the hinge, pointing away from it.
  var a: SIMD3<Double> { SIMD3(-sin(alpha / 2), 0, cos(alpha / 2)) }

  /// Unit vector in the trailing panel, perpendicular to the hinge, pointing away from it.
  var b: SIMD3<Double> { SIMD3(sin(alpha / 2), 0, cos(alpha / 2)) }

  /// Surface normal of the leading panel's display, pointing out of the screen.
  var leadingNormal: SIMD3<Double> { SIMD3(cos(alpha / 2), 0, sin(alpha / 2)) }

  /// Surface normal of the trailing panel's display, pointing out of the screen.
  var trailingNormal: SIMD3<Double> { SIMD3(-cos(alpha / 2), 0, sin(alpha / 2)) }

  /// Angle between the two display normals: π − α.
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
}

extension Double {
  /// Rounds for display and removes negative zero so readouts never show "-0.000".
  func cleaned(fractionDigits: Int) -> Double {
    let scale = pow(10, Double(fractionDigits))
    return (self * scale).rounded() / scale + 0
  }
}
