import Foundation

/// What the outer display shows. Inside is the construction; outside is the consequence.
///
/// Every case is data only: the lesson owns the state and the outer display renders a
/// deterministic projection of it.
enum OuterScene: Equatable {
  case none
  case matrixImage(MatrixImageState)
  case coordinates(CoordinateState)
  case dual(DualState)
  case mapImage(MapState)
  case quantum(QuantumState)
  case orientation(OrientationState)
}

/// The image of the unit circle under the physical basis B.
struct MatrixImageState: Equatable {
  var openingDegrees: Double
}

/// The coordinates B⁻¹ p of the fixed physical vector.
struct CoordinateState: Equatable {
  var openingDegrees: Double
  /// Nil when the basis has collapsed.
  var coefficients: SIMD3<Double>?
  /// |Δp| in meters since the reference position.
  var physicalChange: Double
  /// Largest coordinate change caused by Δp, or nil when collapsed.
  var coefficientSwing: Double?
}

/// The dual measurement grid in V*.
struct DualState: Equatable {
  var openingDegrees: Double
  var vector: SIMD2<Double>
}

/// The codomain W and the image of A.
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
struct OrientationState: Equatable {
  var innerFlux: Double
}
