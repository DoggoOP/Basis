import Foundation
import simd

/// Defines the canonical frame shared with the Duo math engine.
///
/// With gravity alignment, y is up (the hinge direction h). z is the horizontal
/// direction from the phone's screen toward the person holding it at calibration,
/// and x = y × z points to their right (the direction of a).
struct ProbeCalibration {
  var originTranslation: SIMD3<Double>
  var right: SIMD3<Double>
  var up = SIMD3<Double>(0, 1, 0)
  var toward: SIMD3<Double>

  init(origin transform: simd_float4x4) {
    let t = transform.columns.3
    originTranslation = SIMD3(Double(t.x), Double(t.y), Double(t.z))
    // The camera's +z axis points out of the screen, toward the viewer.
    let back = transform.columns.2
    var horizontal = SIMD3(Double(back.x), 0, Double(back.z))
    if simd_length(horizontal) < 1e-3 { horizontal = SIMD3(0, 0, 1) }
    toward = simd_normalize(horizontal)
    right = simd_cross(up, toward)
  }

  /// p = R₀ᵀ (t − t₀), expressed in (right, up, toward).
  func displacement(of transform: simd_float4x4) -> SIMD3<Double> {
    let t = transform.columns.3
    let d = SIMD3(Double(t.x), Double(t.y), Double(t.z)) - originTranslation
    return SIMD3(simd_dot(d, right), simd_dot(d, up), simd_dot(d, toward))
  }
}
