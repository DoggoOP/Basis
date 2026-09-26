import Foundation

/// Each panel is a mirror plane through the hinge. In the cross-section they are
/// lines through the origin, separated by the opening angle.
/// Composing two reflections is a rotation about the hinge by twice that angle.
struct ReflectionComposition {
  enum Mirror: Hashable {
    case a, b
  }

  var openingDegrees: Double

  /// Unit direction of each mirror line in the symmetric top-down cross-section,
  /// in screen-like coordinates where +y points toward the viewer.
  func direction(of mirror: Mirror) -> SIMD2<Double> {
    let half = openingDegrees.degreesToRadians / 2
    return mirror == .a ? SIMD2(-sin(half), cos(half)) : SIMD2(sin(half), cos(half))
  }

  /// R(v) = 2 (v · u) u − v
  func reflect(_ v: SIMD2<Double>, across mirror: Mirror) -> SIMD2<Double> {
    let u = direction(of: mirror)
    return 2 * v.dot(u) * u - v
  }

  func apply(_ sequence: [Mirror], to v: SIMD2<Double>) -> SIMD2<Double> {
    sequence.reduce(v) { reflect($0, across: $1) }
  }

  /// Signed rotation (degrees, −180…180] produced by reflecting across `first`, then `second`.
  /// Reflecting across line θ₁ then θ₂ rotates by 2(θ₂ − θ₁).
  func rotationDegrees(first: Mirror, second: Mirror) -> Double {
    guard first != second else { return 0 }
    let angle = { (m: Mirror) in
      let u = direction(of: m)
      return atan2(u.y, u.x).radiansToDegrees
    }
    return Self.normalized(2 * (angle(second) - angle(first)))
  }

  /// The dihedral angle between the mirror planes, 0…90°.
  var mirrorAngleDegrees: Double { min(openingDegrees, 180 - openingDegrees) }

  /// When the mirrors meet at π/n, the rotation generates a cyclic group of order n.
  var cyclicOrder: Int? {
    let φ = mirrorAngleDegrees
    guard φ > 1 else { return nil }
    let n = (180 / φ).rounded()
    guard n >= 2, n <= 12, abs(180 / n - φ) < 1 else { return nil }
    return Int(n)
  }

  static func normalized(_ degrees: Double) -> Double {
    var d = degrees.truncatingRemainder(dividingBy: 360)
    if d > 180 { d -= 360 }
    if d <= -180 { d += 360 }
    return d
  }
}
