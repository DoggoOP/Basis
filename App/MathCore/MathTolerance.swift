import Foundation

/// Shared thresholds so every lesson agrees on what "orthogonal" and "singular" mean.
enum MathTolerance {
  /// Within this many degrees of 90°, the basis is displayed as exactly orthogonal.
  static let orthogonalSnapDegrees = 1.5
  /// Below this |sin α| the UI treats the basis as collapsed.
  static let singularSine = 0.03
  /// Above this condition number coordinates are too unstable to display.
  static let maximumConditionNumber = 60.0

  /// Snaps the opening angle to 90° when it is within the orthogonal tolerance.
  static func snappedOpening(_ degrees: Double) -> Double {
    let clamped = min(max(degrees, 0), 180)
    return abs(clamped - 90) < orthogonalSnapDegrees ? 90 : clamped
  }

  /// Rounds tiny floating-point noise to exact 0 and ±1.
  static func exact(_ value: Double) -> Double {
    if abs(value) < 1e-12 { return 0 }
    if abs(abs(value) - 1) < 1e-12 { return value > 0 ? 1 : -1 }
    return value
  }
}

extension Double {
  /// Rounds for display and removes negative zero so readouts never show "-0.000".
  func cleaned(fractionDigits: Int) -> Double {
    let scale = pow(10, Double(fractionDigits))
    return (self * scale).rounded() / scale + 0
  }

  var degreesToRadians: Double { self * .pi / 180 }
  var radiansToDegrees: Double { self * 180 / .pi }
}
