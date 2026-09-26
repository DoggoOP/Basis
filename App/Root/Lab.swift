import Foundation

/// The independent labs in Explore Mode.
enum Lab: String, CaseIterable, Identifiable, Hashable {
  case matrix, coordinates, duality, maps, orthogonalize, reflections, qubit, surface

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
    case .surface: "Surface"
    }
  }

  var subtitle: String {
    switch self {
    case .matrix: "SVD, determinant, conditioning"
    case .coordinates: "Change of basis + physical probe"
    case .duality: "Build vectors vs measure vectors"
    case .maps: "Kernel, image, rank, invertibility"
    case .orthogonalize: "Gram–Schmidt / QR"
    case .reflections: "Two planes compose into a rotation"
    case .qubit: "Measurement geometry"
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
