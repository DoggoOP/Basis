import Foundation

/// The independent labs in Explore Mode.
enum Lab: String, CaseIterable, Identifiable, Hashable {
  case directions, physicalPoint, conditioning, duality, qubit, maps, orthogonalize, reflections, flux, surface

  var id: Self { self }

  var title: String {
    switch self {
    case .directions: "Directions"
    case .physicalPoint: "Hold the Point"
    case .conditioning: "Break the Basis"
    case .duality: "Rulers"
    case .qubit: "Qubit"
    case .maps: "Maps"
    case .orthogonalize: "Orthogonalize"
    case .reflections: "Reflections"
    case .flux: "Flux"
    case .surface: "Surface"
    }
  }

  var subtitle: String {
    switch self {
    case .directions: "Coordinates are travel instructions"
    case .physicalPoint: "Same point, rotated frame, new coordinates"
    case .conditioning: "Nearly parallel roads, absurd routes"
    case .duality: "The dual basis measures how much a and b"
    case .qubit: "Screen normals as Bloch axes"
    case .maps: "Input inside, output outside"
    case .orthogonalize: "Remove what you already have"
    case .reflections: "The panels are the mirrors"
    case .flux: "Inner normal n, outer normal −n"
    case .surface: "Intrinsic vs extrinsic distance"
    }
  }

  var systemImage: String {
    switch self {
    case .directions: "point.topleft.down.to.point.bottomright.curvepath"
    case .physicalPoint: "iphone.radiowaves.left.and.right"
    case .conditioning: "angle"
    case .duality: "ruler"
    case .qubit: "atom"
    case .maps: "function"
    case .orthogonalize: "perspective"
    case .reflections: "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
    case .flux: "arrow.up.arrow.down"
    case .surface: "move.3d"
    }
  }

  /// Whether the lab's mathematics depends on the physical hinge angle.
  var usesHinge: Bool { self != .maps }
}

enum Route: Hashable {
  case explore
  case lab(Lab)
  case probe
  case calibration
}
