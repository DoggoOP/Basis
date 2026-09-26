import Foundation

/// A pure qubit prepared along panel A's normal and measured along panel B's normal.
struct QuantumMeasurement {
  /// Angle between the two Bloch axes: θ = π − α.
  var normalAngleDegrees: Double

  init(openingDegrees: Double) {
    normalAngleDegrees = FoldGeometry(openingDegrees: openingDegrees).normalAngleDegrees
  }

  /// n_A · n_B = cos θ
  var axisDot: Double { MathTolerance.exact(cos(normalAngleDegrees.degreesToRadians)) }

  /// P(+) = (1 + n_A · n_B) / 2 = cos²(θ/2)
  var pPlus: Double { (1 + axisDot) / 2 }

  var pMinus: Double { 1 - pPlus }

  var regime: MeasurementRegime {
    switch normalAngleDegrees {
    case ..<3: .aligned
    case 87...93: .unbiased
    case 177...: .opposed
    default: .partial
    }
  }
}

enum MeasurementRegime {
  case aligned, partial, unbiased, opposed

  var title: String {
    switch self {
    case .aligned: "Deterministic"
    case .partial: "Biased"
    case .unbiased: "Mutually Unbiased"
    case .opposed: "Deterministic"
    }
  }

  var explanation: String {
    switch self {
    case .aligned: "The axes align. Every shot is +."
    case .partial: "Tilted axes. Random, but biased."
    case .unbiased: "Perpendicular Bloch axes. A fair coin."
    case .opposed: "Opposite axes. Every shot is −."
    }
  }
}

/// A fixed sequence of uniform draws. Each shot is + when its draw is below P(+),
/// so folding changes outcomes smoothly instead of reshuffling them, and every reset
/// replays the same rehearsable sequence.
struct MeasurementShots {
  static let count = 400
  static let demoSeed: UInt64 = 0xB4515

  private(set) var draws: [Double]

  init(seed: UInt64 = demoSeed) {
    var generator = SplitMix64(seed: seed)
    draws = (0..<Self.count).map { _ in Double.random(in: 0..<1, using: &generator) }
  }

  func outcome(at index: Int, pPlus: Double) -> Bool { draws[index] < pPlus }

  func plusCount(firstShots n: Int, pPlus: Double) -> Int {
    draws.prefix(n).lazy.filter { $0 < pPlus }.count
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
