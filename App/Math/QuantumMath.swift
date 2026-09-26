import Foundation

/// A pure qubit prepared along one Bloch axis and measured along another.
struct QubitMeasurement {
  /// Angle between the preparation and measurement Bloch axes.
  var axisAngleDegrees: Double

  /// Uses the two display normals as the Bloch axes: θ = π − α.
  init(openingDegrees: Double) {
    axisAngleDegrees = FoldGeometry(openingDegrees: openingDegrees).normalAngleDegrees
  }

  /// P(+) = (1 + n_p · n_m) / 2 = cos²(θ/2)
  var probabilityPlus: Double {
    let half = axisAngleDegrees * .pi / 360
    return cos(half) * cos(half)
  }

  var probabilityMinus: Double { 1 - probabilityPlus }

  /// n_p · n_m = cos θ
  var axisDot: Double { cos(axisAngleDegrees * .pi / 180) }

  var regime: MeasurementRegime {
    switch axisAngleDegrees {
    case ..<3: .aligned
    case 87...93: .unbiased
    case 177...: .opposed
    default: .partial
    }
  }
}

enum MeasurementRegime {
  case aligned, partial, unbiased, opposed

  var explanation: String {
    switch self {
    case .aligned: "Aligned axes. The outcome is certain."
    case .partial: "Tilted axes. Outcomes are random, but biased."
    case .unbiased: "Perpendicular Bloch axes. Mutually unbiased: a fair coin."
    case .opposed: "Opposite axes. The outcome is certainly −."
    }
  }
}

/// A fixed set of uniform random draws. Each shot is + when its draw is below P(+),
/// so folding the device changes outcomes smoothly instead of reshuffling them.
struct MeasurementShots {
  static let count = 500

  private(set) var draws: [Double]

  init(seed: UInt64) {
    var generator = SplitMix64(seed: seed)
    draws = (0..<Self.count).map { _ in Double.random(in: 0..<1, using: &generator) }
  }

  func outcomes(probabilityPlus: Double) -> [Bool] {
    draws.map { $0 < probabilityPlus }
  }

  func plusCount(probabilityPlus: Double) -> Int {
    draws.lazy.filter { $0 < probabilityPlus }.count
  }
}

struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) { state = seed }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
