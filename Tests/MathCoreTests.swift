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

  @Test(arguments: [0.0, 0.5, 179.5, 180])
  func singularityGuardTriggers(degrees: Double) {
    #expect(BasisGeometry(openingDegrees: degrees).isSingular)
  }
}

struct ChangeOfBasisTests {
  @Test(arguments: [20.0, 45, 75, 120, 160])
  func solveReconstructsVector(degrees: Double) throws {
    let p = SIMD3(0.42, 0.18, 0.31)
    let solve = ChangeOfBasis(basis: BasisGeometry(openingDegrees: degrees), vector: p)
    let c = try #require(solve.coefficients)
    #expect((solve.reconstruct(from: c) - p).length < 1e-9)
    let alpha = degrees.degreesToRadians
    #expect(near(c.z, 0.18))
    #expect(near(c.y, 0.31 / sin(alpha)))
    #expect(near(c.x, 0.42 - 0.31 / tan(alpha)))
  }

  @Test func collapsedBasisHasNoCoordinates() {
    #expect(ChangeOfBasis(basis: BasisGeometry(openingDegrees: 179.5), vector: SIMD3(1, 1, 1)).coefficients == nil)
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
