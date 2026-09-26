import Foundation

/// What the outer display shows. Inside is the construction; outside is the consequence:
/// "What does this physical construction imply?"
///
/// Every case is data only: the lesson owns the state and the outer display renders a
/// deterministic projection of it.
enum OuterScene: Equatable {
  case none
  case coordinates(CoordinateState)
  case reachableRegion(ReachableRegionState)
  case dualRulers(DualState)
  case mapImage(MapState)
  case quantumShots(QuantumState)
  case flux(FluxState)
}

/// Where the route lands, and the compact coordinates of the point.
struct CoordinateState: Equatable {
  var openingDegrees: Double
  /// The point in the Duo frame, in steps.
  var pointInDuo: SIMD3<Double>
  /// Nil when no unique route exists.
  var coefficients: SIMD3<Double>?
  /// 0…3 through the route's legs.
  var progress: Double
  /// The compact tuple appears only after the route has been traveled.
  var revealsTuple: Bool
}

/// The region reachable with bounded travel, and the effort ellipse (SVD).
struct ReachableRegionState: Equatable {
  var openingDegrees: Double
  var showsNumbers: Bool
}

/// The dual rulers around the point.
struct DualState: Equatable {
  var openingDegrees: Double
  var point: SIMD2<Double>
}

/// The output space W and the image of A.
struct MapState: Equatable {
  var matrix: Matrix2
  var x: SIMD2<Double>
  /// Kernel/image labels appear only after the geometry has morphed.
  var showsLabels: Bool
}

/// What nature returns: shots and the resulting histogram.
struct QuantumState: Equatable {
  var pPlus: Double
  var shotCount: Int
  var plusCount: Int
  var recentOutcomes: [Bool]
}

/// The outer face's normal is −n, so its flux has the opposite sign.
struct FluxState: Equatable {
  var innerFlux: Double
}
