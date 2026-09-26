import Foundation

/// A 2×2 real matrix [[m11, m12], [m21, m22]].
struct Matrix2: Equatable {
  var m11: Double, m12: Double
  var m21: Double, m22: Double

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

  private func normalized(_ v: SIMD2<Double>) -> SIMD2<Double> {
    v / (v.x * v.x + v.y * v.y).squareRoot()
  }
}

enum TransformPreset: String, CaseIterable, Identifiable {
  case rotation, shear, projection

  var id: Self { self }

  var title: String {
    switch self {
    case .rotation: "Rotation"
    case .shear: "Shear"
    case .projection: "Projection"
    }
  }

  var matrix: Matrix2 {
    switch self {
    case .rotation: Matrix2(m11: 0, m12: -1, m21: 1, m22: 0)
    case .shear: Matrix2(m11: 1, m12: 1, m21: 0, m22: 1)
    case .projection: Matrix2(m11: 1, m12: 0, m21: 0, m22: 0)
    }
  }
}

/// Mapping properties of a linear map R² → R², derived from its rank.
struct TransformProperties {
  var matrix: Matrix2

  var isInjective: Bool { matrix.rank == 2 }
  var isSurjective: Bool { matrix.rank == 2 }
  var isBijective: Bool { isInjective && isSurjective }
  var isInvertible: Bool { isBijective }

  /// |det A|: how much the map scales areas.
  var areaScale: Double { abs(matrix.determinant) }
}
