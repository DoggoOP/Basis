import SwiftUI

/// Semantic colors. Each is assigned once and never changes meaning.
enum Theme {
  /// a, the first basis direction.
  static let first = Color(red: 1.0, green: 0.82, blue: 0.3)
  /// b, the second basis direction.
  static let second = Color(red: 0.35, green: 0.8, blue: 1.0)
  /// The hinge, cross-product axis, and invariants.
  static let hinge = Color(red: 0.4, green: 0.9, blue: 0.55)
  /// The probe vector p.
  static let probe = Color(red: 1.0, green: 0.35, blue: 0.7)
  /// Dual objects and measurements.
  static let dual = Color(red: 0.68, green: 0.55, blue: 1.0)
  /// Neutral grids and equations.
  static let neutral = Color(white: 0.92)
  /// Warnings and singularity.
  static let warning = Color(red: 1.0, green: 0.42, blue: 0.3)

  /// Deep navy blackboard.
  static let background = Color(red: 0.027, green: 0.035, blue: 0.07)
  static let spine = Color(red: 0.06, green: 0.075, blue: 0.13)
  static let grid = Color.white.opacity(0.07)
  static let gridStrong = Color.white.opacity(0.16)
}

/// Motion used across lessons: restrained springs, never bouncy.
enum Motion {
  static let reveal = Animation.smooth(duration: 0.45)
  static let morph = Animation.smooth(duration: 0.8)
  static let step = Animation.snappy(duration: 0.5)
}
