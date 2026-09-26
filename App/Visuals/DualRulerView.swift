import SwiftUI

/// The dual basis as measuring rulers: ωᵃ's level lines run parallel to b and read how much
/// a a point contains; ωᵇ's run parallel to a. Crossing one line changes the reading by one.
/// As a and b become indistinguishable, the rulers pack together and become absurdly sensitive.
struct DualRulerView: View {
  var basis: BasisGeometry
  /// The point, in the cross-section.
  var point: SIMD2<Double>

  private static let maximumLines = 160

  var body: some View {
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 2.4, duoTopDown: true)
      if basis.isSingular {
        context.drawLine(through: .zero, direction: basis.a2, in: mapping, size: size, color: Theme.warning.opacity(0.8), lineWidth: 3)
      } else {
        let reach = Double(max(size.width, size.height) / mapping.unit)
        let separation = abs(basis.sine)
        let count = min(Int(reach / separation) + 1, Self.maximumLines)
        let labelsFit = separation * Double(mapping.unit) > 26
        for i in -count...count {
          let k = Double(i)
          let emphasis = i == 0 ? 0.95 : 0.5
          // ωᵃ = k: through k·a, parallel to b.
          context.drawLine(through: basis.a2 * k, direction: basis.b2, in: mapping, size: size, color: Theme.dual.opacity(emphasis), lineWidth: 1.6)
          // ωᵇ = k: through k·b, parallel to a.
          context.drawLine(through: basis.b2 * k, direction: basis.a2, in: mapping, size: size, color: Theme.dual.opacity(emphasis * 0.55), lineWidth: 1.2, dash: [4, 5])
          if labelsFit, abs(i) <= 3 {
            context.draw(tick(i, tint: Theme.first), at: mapping.point(basis.a2 * k - basis.b2 * 0.22))
            if i != 0 {
              context.draw(tick(i, tint: Theme.second), at: mapping.point(basis.b2 * k - basis.a2 * 0.22))
            }
          }
        }
      }
      context.drawVector(point, in: mapping, color: Theme.probe, lineWidth: 5, label: "P")
    }
    .accessibilityElement()
    .accessibilityLabel("Dual rulers around P")
  }

  private func tick(_ i: Int, tint: Color) -> Text {
    Text(i > 0 ? "+\(i)" : "\(i)")
      .font(.caption2.weight(.bold))
      .foregroundStyle(tint.opacity(0.9))
  }
}
