import Foundation

/// Converts the device API's raw hinge angle into the physical opening angle α.
///
/// Calibration checklist on the Duo simulator (see the Calibration lab):
/// 1. fully open should read α = 180°,
/// 2. a right-angle pose should read α = 90°,
/// 3. nearly closed should read α ≈ 0°.
/// If the raw angle decreases as the device opens, switch `convention` to `.foldAngle`.
enum HingeCalibration {
  enum Convention {
    /// The API reports the opening angle directly (0° closed, 180° flat).
    case openingAngle
    /// The API reports how far the device is folded (0° flat, 180° closed).
    case foldAngle
  }

  static let convention = Convention.openingAngle

  static func openingDegrees(fromRaw raw: Double) -> Double {
    switch convention {
    case .openingAngle: raw
    case .foldAngle: 180 - raw
    }
  }
}
