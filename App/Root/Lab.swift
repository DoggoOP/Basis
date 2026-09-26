import Foundation

/// The independent labs in Explore Mode.
enum Lab: String, CaseIterable, Identifiable, Hashable {
  case matrix, coordinates, duality, maps, orthogonalize, reflections, qubit, orientation, surface

  var id: Self { self }

  var title: String {
    switch self {
    case .matrix: "Matrix"
    case .coordinates: "Coordinates"
    case .duality: "Duality"
    case .maps: "Maps"
    case .orthogonalize: "Orthogonalize"
    case .reflections: "Reflections"
    case .qubit: "Qubit"
    case .orientation: "Orientation"
    case .surface: "Surface"
    }
  }

  var subtitle: String {
    switch self {
    case .matrix: "Inner: basis · Outer: transformed unit circle, SVD, conditioning"
    case .coordinates: "Inner: vector + changing basis · Outer: coordinates"
    case .duality: "Inner: primal space · Outer: dual measurement space"
    case .maps: "Inner: domain · Outer: codomain, kernel, image, rank"
    case .orthogonalize: "Gram–Schmidt / QR"
    case .reflections: "Two planes compose into a rotation"
    case .qubit: "Inner: preparation + basis · Outer: measurement outcomes"
    case .orientation: "Inner: normal n · Outer: −n and the opposite flux"
    case .surface: "Intrinsic vs extrinsic distance"
    }
  }

  var systemImage: String {
    switch self {
    case .matrix: "square.grid.2x2"
    case .coordinates: "move.3d"
    case .duality: "ruler"
    case .maps: "function"
    case .orthogonalize: "perspective"
    case .reflections: "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
    case .qubit: "atom"
    case .orientation: "arrow.up.arrow.down"
    case .surface: "point.topleft.down.to.point.bottomright.curvepath"
    }
  }

  /// Whether the lab's mathematics depends on the physical hinge angle.
  var usesHinge: Bool { self != .maps }
}

enum Route: Hashable {
  case demo
  case lab(Lab)
  case probe
  case calibration
}
