import Foundation

/// A point on one panel, described in that panel's own flat coordinates.
struct SurfacePoint: Equatable {
  /// Perpendicular distance from the hinge line.
  var distanceFromHinge: Double
  /// Position along the hinge direction h.
  var alongHinge: Double
}

/// Intrinsic (along the surface) versus extrinsic (through 3D space) distance
/// between a point on each panel.
struct SurfaceGeometry {
  /// Approximate physical size of one point on an iPhone display.
  static let millimetersPerPoint = 0.166

  var a: SurfacePoint
  var b: SurfacePoint
  var openingDegrees: Double

  private var alpha: Double { openingDegrees * .pi / 180 }
  private var alongOffset: Double { b.alongHinge - a.alongHinge }

  /// Geodesic distance: unfold the panels flat and measure a straight line.
  /// Folding never stretches the surface, so this does not depend on α.
  var surfaceDistance: Double {
    let across = a.distanceFromHinge + b.distanceFromHinge
    return (across * across + alongOffset * alongOffset).squareRoot()
  }

  /// Straight-line distance through space: the law of cosines across the fold.
  var spatialDistance: Double {
    let rA = a.distanceFromHinge, rB = b.distanceFromHinge
    let chordSquared = rA * rA + rB * rB - 2 * rA * rB * cos(alpha)
    return (max(chordSquared, 0) + alongOffset * alongOffset).squareRoot()
  }

  /// Where the shortest surface path crosses the hinge, measured along h.
  var hingeCrossingAlong: Double {
    let across = a.distanceFromHinge + b.distanceFromHinge
    guard across > 0 else { return (a.alongHinge + b.alongHinge) / 2 }
    return a.alongHinge + alongOffset * a.distanceFromHinge / across
  }

  /// 3D distance as a fraction of surface distance (1 when flat).
  var ratio: Double {
    surfaceDistance > 0 ? spatialDistance / surfaceDistance : 1
  }
}
