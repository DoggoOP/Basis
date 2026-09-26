import Testing
import simd
@testable import Basis

private func near(_ a: Double, _ b: Double, _ tolerance: Double = 1e-9) -> Bool { abs(a - b) < tolerance }

struct BasisGeometryTests {
  @Test func orthogonalBasisIsPerfectlyConditioned() {
    let g = BasisGeometry(openingDegrees: 90)
    #expect(g.dot == 0)
    #expect(near(g.determinantMagnitude, 1))
    #expect(near(g.sigmaMax, 1))
    #expect(near(g.sigmaMin, 1))
    #expect(near(g.conditionNumber, 1))
  }

  @Test func sixtyDegreesMatchesAnalyticSVD() {
    let g = BasisGeometry(openingDegrees: 60)
    #expect(near(g.determinantMagnitude, 3.0.squareRoot() / 2))
    #expect(near(g.sigmaMax, 1.5.squareRoot()))
    #expect(near(g.sigmaMin, 0.5.squareRoot()))
    #expect(near(g.semiaxes.major.length, g.sigmaMax))
    #expect(near(g.semiaxes.minor.length, g.sigmaMin))
  }

  @Test(arguments: [0.0, 2, 178, 180])
  func singularityGuardTriggers(degrees: Double) {
    #expect(BasisGeometry(openingDegrees: degrees).isSingular)
  }
}

struct CoordinateSolverTests {
  @Test(arguments: [20.0, 45, 75, 120, 160])
  func solveReconstructsPoint(degrees: Double) throws {
    let p = SIMD3(0.42, 0.18, 0.31)
    let solver = CoordinateSolver(basis: BasisGeometry(openingDegrees: degrees), pointWorld: p)
    let c = try #require(solver.coefficients)
    #expect((solver.reconstruct(from: c) - p).length < 1e-9)
    // b = (cos α, 0, −sin α): c_h = y, c_b = −z / sin α, c_a = x + z cot α.
    let alpha = degrees.degreesToRadians
    #expect(near(c.z, 0.18))
    #expect(near(c.y, -0.31 / sin(alpha)))
    #expect(near(c.x, 0.42 + 0.31 / tan(alpha)))
  }

  @Test func presetRouteAtRightAngle() throws {
    let solver = CoordinateSolver(basis: BasisGeometry(openingDegrees: 90), pointWorld: PointSourceModel.presetPoint)
    let c = try #require(solver.coefficients)
    #expect((c - SIMD3(1.4, 0.8, 0.3)).length < 1e-9)
  }

  @Test func collapsedBasisHasNoRoute() {
    #expect(CoordinateSolver(basis: BasisGeometry(openingDegrees: 179), pointWorld: SIMD3(1, 1, 1)).coefficients == nil)
  }

  @Test func rotatingTheFrameMovesCoordinatesNotThePoint() throws {
    let basis = BasisGeometry(openingDegrees: 90)
    let point = SIMD3(0.42, 0.18, -0.31)
    let still = try #require(CoordinateSolver(basis: basis, pointWorld: point).coefficients)
    let rotated = CoordinateSolver(basis: basis, pointWorld: point, frameYaw: 30.0.degreesToRadians)
    let turned = try #require(rotated.coefficients)
    #expect(near(rotated.pointInDuoFrame.length, point.length))
    #expect(near(turned.z, still.z))
    #expect((turned - still).length > 0.1)
  }

  @Test func foldingTowardSingularMakesRoutesLonger() throws {
    let point = PointSourceModel.presetPoint
    let good = try #require(CoordinateSolver(basis: BasisGeometry(openingDegrees: 90), pointWorld: point).coefficients)
    let poor = try #require(CoordinateSolver(basis: BasisGeometry(openingDegrees: 6), pointWorld: point).coefficients)
    #expect(CoordinateRoute(coefficients: poor).travelLength > 3 * CoordinateRoute(coefficients: good).travelLength)
  }
}

struct CoordinateRouteTests {
  @Test func instructionsReadAsTravel() {
    let route = CoordinateRoute(coefficients: SIMD3(2, -1, 0.5))
    #expect(route.instruction(for: .a) == "2 steps along a")
    #expect(route.instruction(for: .b) == "1 step backward along b")
    #expect(route.instruction(for: .h) == "0.5 step along h")
    #expect(route.linearCombination() == "2.0 a − 1.0 b + 0.5 h")
    #expect(route.tuple() == "(2.0, -1.0, 0.5)")
  }

  @Test func legsAreTraveledInOrder() {
    #expect(CoordinateRoute.legProgress(.a, overall: 0.5) == 0.5)
    #expect(CoordinateRoute.legProgress(.b, overall: 0.5) == 0)
    #expect(CoordinateRoute.legProgress(.b, overall: 1.25) == 0.25)
    #expect(CoordinateRoute.legProgress(.h, overall: 3) == 1)
  }
}

struct DualBasisTests {
  @Test(arguments: [30.0, 60, 90, 135])
  func dualPairingIsKroneckerDelta(degrees: Double) {
    #expect(DualBasis(basis: BasisGeometry(openingDegrees: degrees)).pairing == [[1, 0], [0, 1]])
  }

  @Test func noDualBasisWhenSingular() {
    #expect(DualBasis(basis: BasisGeometry(openingDegrees: 0)).omega1 == nil)
  }
}

struct QuantumMeasurementTests {
  @Test func probabilitiesAtLandmarks() {
    #expect(near(QuantumMeasurement(openingDegrees: 180).pPlus, 1))
    #expect(near(QuantumMeasurement(openingDegrees: 90).pPlus, 0.5))
    #expect(near(QuantumMeasurement(openingDegrees: 0).pPlus, 0))
  }

  @Test func seededShotsAreRepeatable() {
    #expect(MeasurementShots().draws == MeasurementShots().draws)
  }
}

struct ReflectionTests {
  @Test(arguments: [30.0, 45, 60, 120])
  func twoReflectionsAreARotationByTwicePhi(degrees: Double) {
    let composition = ReflectionComposition(openingDegrees: degrees)
    let v = SIMD2(0.3, 0.8)
    let rotation = composition.rotationDegrees(first: .a, second: .b).degreesToRadians
    let expected = SIMD2(v.x * cos(rotation) - v.y * sin(rotation), v.x * sin(rotation) + v.y * cos(rotation))
    #expect((composition.apply([.a, .b], to: v) - expected).length < 1e-9)
    #expect(near(abs(composition.rotationDegrees(first: .a, second: .b)), 2 * composition.mirrorAngleDegrees))
    #expect(near(composition.rotationDegrees(first: .b, second: .a), -composition.rotationDegrees(first: .a, second: .b)))
  }

  @Test func fortyFiveDegreesGeneratesCyclicGroupOfOrderFour() {
    #expect(ReflectionComposition(openingDegrees: 45).cyclicOrder == 4)
  }
}

struct GramSchmidtTests {
  @Test func producesOrthonormalPair() throws {
    let gs = GramSchmidt(basis: BasisGeometry(openingDegrees: 60))
    let q2 = try #require(gs.q2)
    #expect(near(q2.dot(gs.q1), 0))
    #expect(near(q2.length, 1))
  }
}

struct OrientedFluxTests {
  @Test(arguments: [0.0, 45, 90, 135, 180])
  func outerFaceHasOppositeFlux(degrees: Double) {
    let flux = OrientedFlux(openingDegrees: degrees)
    #expect(flux.outerFlux == -flux.innerFlux)
  }

  @Test func fluxFollowsNormalAlignment() {
    #expect(near(OrientedFlux(openingDegrees: 180).innerFlux, OrientedFlux.fieldStrength))
    #expect(OrientedFlux(openingDegrees: 90).innerFlux == 0)
  }
}

struct MeasurementShotsTests {
  @Test func recentOutcomesAreTheLatestShots() {
    let shots = MeasurementShots()
    let recent = shots.recentOutcomes(shownShots: 50, pPlus: 0.5, limit: 10)
    #expect(recent.count == 10)
    #expect(recent == (40..<50).map { shots.outcome(at: $0, pPlus: 0.5) })
  }
}
