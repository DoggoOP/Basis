import Foundation

/// Gram–Schmidt on the physical pair [a b], giving A = QR.
struct GramSchmidt {
  var basis: BasisGeometry

  /// q₁ = a / |a|
  var q1: SIMD2<Double> { basis.a2 }

  /// proj_{q₁} b: the part of b that a already explains.
  var projection: SIMD2<Double> { q1 * basis.b2.dot(q1) }

  /// u₂ = b − proj_{q₁} b: what is genuinely new.
  var residual: SIMD2<Double> { basis.b2 - projection }

  /// q₂ = u₂ / |u₂|, or nil when nothing new remains.
  var q2: SIMD2<Double>? {
    let length = residual.length
    return length < MathTolerance.singularSine ? nil : residual / length
  }

  /// R = [[1, cos α], [0, sin α]] (upper triangular).
  var r: (r11: Double, r12: Double, r22: Double) {
    (1, basis.cosine, basis.sine)
  }
}

enum GramSchmidtStep: Int, CaseIterable, Comparable {
  case original, keepFirst, removeProjection, normalize

  static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

  var title: String {
    switch self {
    case .original: "Oblique basis"
    case .keepFirst: "Keep the first direction"
    case .removeProjection: "Remove what's already explained"
    case .normalize: "Normalize"
    }
  }

  var next: Self? { Self(rawValue: rawValue + 1) }
}
