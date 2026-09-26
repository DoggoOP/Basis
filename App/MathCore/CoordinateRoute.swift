import Foundation

/// Coordinates as a route: how far to travel along each available direction.
struct CoordinateRoute: Equatable {
  enum Leg: Int, CaseIterable, Identifiable {
    case a, b, h

    var id: Self { self }

    var symbol: String {
      switch self {
      case .a: "a"
      case .b: "b"
      case .h: "h"
      }
    }
  }

  /// (c_a, c_b, c_h)
  var coefficients: SIMD3<Double>

  func amount(_ leg: Leg) -> Double {
    switch leg {
    case .a: coefficients.x
    case .b: coefficients.y
    case .h: coefficients.z
    }
  }

  /// Total distance traveled along the route, in steps.
  var travelLength: Double { abs(coefficients.x) + abs(coefficients.y) + abs(coefficients.z) }

  /// How much of `leg` has been traveled when the whole route is `progress` ∈ 0…3 complete.
  static func legProgress(_ leg: Leg, overall progress: Double) -> Double {
    min(max(progress - Double(leg.rawValue), 0), 1)
  }

  /// "1.4 steps along a", "1 step backward along b".
  func instruction(for leg: Leg, fractionDigits: Int = 1) -> String {
    let value = amount(leg)
    let magnitude = abs(value).cleaned(fractionDigits: fractionDigits)
    let count = magnitude.formatted(.number.precision(.fractionLength(0...fractionDigits)))
    let unit = magnitude > 1 ? "steps" : "step"
    let direction = value < 0 && magnitude > 0 ? " backward" : ""
    return "\(count) \(unit)\(direction) along \(leg.symbol)"
  }

  /// "1.4 a + 0.8 b + 0.3 h"
  func linearCombination(fractionDigits: Int = 1) -> String {
    Leg.allCases.enumerated().map { index, leg in
      let value = amount(leg).cleaned(fractionDigits: fractionDigits)
      let magnitude = abs(value).formatted(.number.precision(.fractionLength(fractionDigits)))
      let sign = value < 0 ? "− " : (index == 0 ? "" : "+ ")
      return "\(sign)\(magnitude) \(leg.symbol)"
    }
    .joined(separator: " ")
  }

  /// "(1.4, 0.8, 0.3)"
  func tuple(fractionDigits: Int = 1) -> String {
    let parts = Leg.allCases.map { amount($0).cleaned(fractionDigits: fractionDigits).formatted(.number.precision(.fractionLength(fractionDigits))) }
    return "(" + parts.joined(separator: ", ") + ")"
  }
}
