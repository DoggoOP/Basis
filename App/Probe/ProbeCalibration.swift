import Foundation
import simd

/// Defines the canonical frame shared with the Duo math engine.
///
/// Matches the Duo frame: y is up (the hinge h, via gravity alignment); x points to the
/// holder's left, like a on panel A; z points away from them, so b folds toward them.
/// (left, up, away) is right-handed.
struct ProbeCalibration {
  var originTranslation: SIMD3<Double>
  var originRotation: simd_quatd
  var left: SIMD3<Double>
  var up = SIMD3<Double>(0, 1, 0)
  var away: SIMD3<Double>

  init(origin transform: simd_float4x4) {
    let t = transform.columns.3
    originTranslation = SIMD3(Double(t.x), Double(t.y), Double(t.z))
    // The camera's +z axis points out of the screen, toward the viewer.
    let back = transform.columns.2
    var horizontal = SIMD3(Double(back.x), 0, Double(back.z))
    if simd_length(horizontal) < 1e-3 { horizontal = SIMD3(0, 0, 1) }
    let toward = simd_normalize(horizontal)
    away = -toward
    left = -simd_cross(up, toward)
    originRotation = Self.rotation(of: transform)
  }

  /// p = R₀ᵀ (t − t₀), expressed in (left, up, away).
  func displacement(of transform: simd_float4x4) -> SIMD3<Double> {
    let t = transform.columns.3
    let d = SIMD3(Double(t.x), Double(t.y), Double(t.z)) - originTranslation
    return SIMD3(simd_dot(d, left), simd_dot(d, up), simd_dot(d, away))
  }

  /// Orientation relative to the origin pose.
  func relativeRotation(of transform: simd_float4x4) -> simd_quatd {
    Self.rotation(of: transform) * originRotation.inverse
  }

  private static func rotation(of transform: simd_float4x4) -> simd_quatd {
    let m = simd_double3x3(
      SIMD3(Double(transform.columns.0.x), Double(transform.columns.0.y), Double(transform.columns.0.z)),
      SIMD3(Double(transform.columns.1.x), Double(transform.columns.1.y), Double(transform.columns.1.z)),
      SIMD3(Double(transform.columns.2.x), Double(transform.columns.2.y), Double(transform.columns.2.z))
    )
    return simd_quatd(m)
  }
}
