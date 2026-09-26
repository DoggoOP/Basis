import Foundation

/// Everything the Basis lesson shows, derived from the physical opening angle.
struct BasisState {
  /// Within this many degrees of 90°, the pair is treated as exactly orthogonal.
  static let orthogonalSnap = 1.5
  /// Within this many degrees of 0° or 180°, the pair is treated as exactly dependent.
  static let dependentSnap = 0.75

  var openingDegrees: Double
  var isSwapped = false

  init(openingDegrees: Double, isSwapped: Bool = false) {
    let clamped = min(max(openingDegrees, 0), 180)
    if abs(clamped - 90) < Self.orthogonalSnap {
      self.openingDegrees = 90
    } else if clamped < Self.dependentSnap {
      self.openingDegrees = 0
    } else if clamped > 180 - Self.dependentSnap {
      self.openingDegrees = 180
    } else {
      self.openingDegrees = clamped
    }
    self.isSwapped = isSwapped
  }

  private var geometry: FoldGeometry { FoldGeometry(openingDegrees: openingDegrees) }

  /// a · b = cos α
  var dot: Double { exact(geometry.a.dot(geometry.b)) }

  /// The first-times-second cross product; lies along the hinge direction h.
  var cross: SIMD3<Double> {
    isSwapped ? geometry.b.cross(geometry.a) : geometry.a.cross(geometry.b)
  }

  /// |a × b| = sin α
  var crossMagnitude: Double { exact(sin(geometry.alpha)) }

  /// +1 when the cross product points up the hinge, −1 when it points down, 0 when it vanishes.
  var crossDirection: Double {
    crossMagnitude == 0 ? 0 : (cross.y > 0 ? 1 : -1)
  }

  /// Oriented area of the parallelogram spanned by the ordered pair: the 2×2 determinant.
  var determinant: Double { crossMagnitude * (isSwapped ? -1 : 1) }

  /// Gram matrix G = [[1, cos α], [cos α, 1]].
  var gram: (Double, Double, Double, Double) { (1, dot, dot, 1) }

  /// det G = sin²α
  var gramDeterminant: Double { crossMagnitude * crossMagnitude }

  /// Condition number of G: (1 + |cos α|) / (1 − |cos α|). Nil when singular.
  var conditionNumber: Double? {
    let c = abs(dot)
    return c >= 1 ? nil : (1 + c) / (1 - c)
  }

  /// How far the pair is from being parallel, in degrees (90° is the best possible).
  var separationDegrees: Double { min(openingDegrees, 180 - openingDegrees) }

  var relation: VectorRelation {
    if openingDegrees == 90 { return .orthogonal }
    if separationDegrees == 0 { return .dependent }
    if separationDegrees < 12 { return .nearlyDependent }
    return .independent
  }

  var quality: BasisQuality {
    switch separationDegrees {
    case 75...: .excellent
    case 40..<75: .good
    case 12..<40: .poor
    case let d where d > 0: .illConditioned
    default: .singular
    }
  }

  /// Snaps values that are exact at special angles, so 90° reads as exactly 0.
  private func exact(_ value: Double) -> Double {
    abs(value) < 1e-12 ? 0 : (abs(abs(value) - 1) < 1e-12 ? (value > 0 ? 1 : -1) : value)
  }
}

enum VectorRelation {
  case orthogonal, independent, nearlyDependent, dependent

  var title: String {
    switch self {
    case .orthogonal: "Orthogonal"
    case .independent: "Independent"
    case .nearlyDependent: "Nearly Dependent"
    case .dependent: "Linearly Dependent"
    }
  }
}

enum BasisQuality: CaseIterable {
  case excellent, good, poor, illConditioned, singular

  var title: String {
    switch self {
    case .excellent: "Excellent"
    case .good: "Good"
    case .poor: "Poor"
    case .illConditioned: "Ill-Conditioned"
    case .singular: "Singular"
    }
  }
}
