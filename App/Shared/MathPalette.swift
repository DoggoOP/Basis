import SwiftUI

/// One consistent color vocabulary across every lesson.
enum MathPalette {
  /// Vector a, point A, the preparation axis, the domain.
  static let first = Color.orange
  /// Vector b, point B, the measurement axis, the codomain.
  static let second = Color.cyan
  /// Cross products, hinge axes, kernels and images.
  static let axis = Color.pink
  /// Intrinsic, surface-bound quantities.
  static let intrinsic = Color.mint

  static let panelBackground = Color(white: 0.055)
  static let spineBackground = Color(white: 0.11)
  static let grid = Color.white.opacity(0.06)
}
