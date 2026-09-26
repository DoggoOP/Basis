import Foundation
import simd

/// The Duo as a matrix. Columns are the physical panel directions, written in the
/// frame of panel A: a = (1, 0, 0), b = (cos α, 0, sin α), h = (0, 1, 0).
/// The 2D cross-section perpendicular to the hinge keeps a = (1, 0), b = (cos α, sin α).
struct BasisGeometry {
  /// Physical opening angle in radians, 0…π.
  var alpha: Double

  init(alpha: Double) {
    self.alpha = min(max(alpha, 0), .pi)
  }

  init(openingDegrees: Double) {
    self.init(alpha: MathTolerance.snappedOpening(openingDegrees).degreesToRadians)
  }

  var openingDegrees: Double { alpha.radiansToDegrees }

  var cosine: Double { MathTolerance.exact(cos(alpha)) }
  var sine: Double { MathTolerance.exact(sin(alpha)) }

  // MARK: 2D cross-section

  var a2: SIMD2<Double> { SIMD2(1, 0) }
  var b2: SIMD2<Double> { SIMD2(cosine, sine) }

  /// B₂ = [a b] = [[1, cos α], [0, sin α]] (columns are a and b).
  var B2: simd_double2x2 { simd_double2x2(columns: (a2, b2)) }

  // MARK: 3D basis

  var a3: SIMD3<Double> { SIMD3(1, 0, 0) }
  var b3: SIMD3<Double> { SIMD3(cosine, 0, sine) }
  var hinge: SIMD3<Double> { SIMD3(0, 1, 0) }

  /// B₃ = [a b h].
  var B3: simd_double3x3 { simd_double3x3(columns: (a3, b3, hinge)) }

  // MARK: Invariants

  /// a · b = cos α
  var dot: Double { cosine }

  /// |det B| = |sin α|: the area of the parallelogram spanned by a and b.
  var determinantMagnitude: Double { abs(sine) }

  /// σ_max = √(1 + |cos α|)
  var sigmaMax: Double { (1 + abs(cosine)).squareRoot() }

  /// σ_min = √(1 − |cos α|)
  var sigmaMin: Double { (1 - abs(cosine)).squareRoot() }

  /// κ(B₂) = σ_max / σ_min; infinite when singular.
  var conditionNumber: Double {
    sigmaMin > 1e-12 ? sigmaMax / sigmaMin : .infinity
  }

  /// True when the UI should treat the basis as collapsed.
  var isSingular: Bool { abs(sine) < MathTolerance.singularSine }

  var isOrthogonal: Bool { cosine == 0 }

  var rank: Int { isSingular ? 1 : 2 }

  /// Right singular vectors (in coefficient space) for σ_max and σ_min.
  /// BᵀB = [[1, c], [c, 1]] has eigenvectors (1, ±1)/√2.
  var rightSingularVectors: (max: SIMD2<Double>, min: SIMD2<Double>) {
    let r = 1 / 2.0.squareRoot()
    let plus = SIMD2(r, r), minus = SIMD2(r, -r)
    return cosine >= 0 ? (plus, minus) : (minus, plus)
  }

  /// Ellipse semiaxes in physical space: B v for each right singular vector.
  var semiaxes: (major: SIMD2<Double>, minor: SIMD2<Double>) {
    let v = rightSingularVectors
    return (B2 * v.max, B2 * v.min)
  }

  var quality: BasisQuality {
    if isSingular { return .singular }
    if isOrthogonal { return .orthonormal }
    switch conditionNumber {
    case ..<2.5: return .stable
    case ..<25: return .sensitive
    default: return .unstable
    }
  }
}

enum BasisQuality {
  case orthonormal, stable, sensitive, unstable, singular

  var title: String {
    switch self {
    case .orthonormal: "Orthonormal"
    case .stable: "Stable"
    case .sensitive: "Sensitive"
    case .unstable: "Unstable"
    case .singular: "Singular"
    }
  }

  var detail: String {
    switch self {
    case .orthonormal: "B = I in the cross-section"
    case .stable: "Coordinates are well-behaved"
    case .sensitive: "Small errors grow"
    case .unstable: "Coordinates barely mean anything"
    case .singular: "No unique coordinates"
    }
  }
}
