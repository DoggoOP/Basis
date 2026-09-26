import Foundation

/// A 2×2 real matrix [[m11, m12], [m21, m22]].
struct Matrix2: Equatable {
  var m11: Double, m12: Double
  var m21: Double, m22: Double

  static let identity = Matrix2(m11: 1, m12: 0, m21: 0, m22: 1)

  func apply(_ v: SIMD2<Double>) -> SIMD2<Double> {
    SIMD2(m11 * v.x + m12 * v.y, m21 * v.x + m22 * v.y)
  }

  var determinant: Double { m11 * m22 - m12 * m21 }

  var rank: Int {
    if abs(determinant) > 1e-9 { return 2 }
    return [m11, m12, m21, m22].contains { abs($0) > 1e-9 } ? 1 : 0
  }

  /// A unit direction spanning ker A when rank is 1.
  var kernelDirection: SIMD2<Double>? {
    guard rank == 1 else { return nil }
    let row = abs(m11) + abs(m12) > 1e-9 ? SIMD2(m11, m12) : SIMD2(m21, m22)
    return normalized(SIMD2(-row.y, row.x))
  }

  /// A unit direction spanning im A when rank is 1.
  var imageDirection: SIMD2<Double>? {
    guard rank == 1 else { return nil }
    let column = abs(m11) + abs(m21) > 1e-9 ? SIMD2(m11, m21) : SIMD2(m12, m22)
    return normalized(column)
  }

  /// Singular values (σ₁ ≥ σ₂) from the closed form for 2×2 matrices.
  var singularValues: (Double, Double) {
    let q = m11 * m11 + m12 * m12 + m21 * m21 + m22 * m22
    let d = abs(determinant)
    let root = max(q * q - 4 * d * d, 0).squareRoot()
    return (((q + root) / 2).squareRoot(), (max(q - root, 0) / 2).squareRoot())
  }

  func interpolated(to other: Matrix2, fraction t: Double) -> Matrix2 {
    Matrix2(
      m11: m11 + (other.m11 - m11) * t, m12: m12 + (other.m12 - m12) * t,
      m21: m21 + (other.m21 - m21) * t, m22: m22 + (other.m22 - m22) * t
    )
  }

  private func normalized(_ v: SIMD2<Double>) -> SIMD2<Double> { v / v.length }
}

enum LinearMapPreset: String, CaseIterable, Identifiable {
  case rotate, shear, stretch, collapse

  var id: Self { self }

  var title: String {
    switch self {
    case .rotate: "Rotate"
    case .shear: "Shear"
    case .stretch: "Stretch"
    case .collapse: "Collapse"
    }
  }

  var matrix: Matrix2 {
    switch self {
    case .rotate:
      let t = 30.0.degreesToRadians
      return Matrix2(m11: cos(t), m12: -sin(t), m21: sin(t), m22: cos(t))
    case .shear: return Matrix2(m11: 1, m12: 0.8, m21: 0, m22: 1)
    case .stretch: return Matrix2(m11: 1.6, m12: 0, m21: 0, m22: 0.55)
    case .collapse: return Matrix2(m11: 1, m12: 0, m21: 0, m22: 0)
    }
  }
}

/// Mapping properties of a linear map R² → R², derived from its rank.
struct LinearMapProperties {
  var matrix: Matrix2

  var rank: Int { matrix.rank }
  var isInjective: Bool { rank == 2 }
  var isSurjective: Bool { rank == 2 }
  var isInvertible: Bool { rank == 2 }

  /// |det A|: how much the map scales areas.
  var areaScale: Double { abs(matrix.determinant) }
}
