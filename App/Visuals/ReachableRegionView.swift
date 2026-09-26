import SwiftUI

/// What the basis can reach: the region reachable with bounded travel (|c| ≤ 1 per
/// direction), and the ellipse reachable with one unit of total effort (|c| = 1).
/// The ellipse's long radius is the easiest direction to move; its short radius the hardest.
struct ReachableRegionView: View {
  var basis: BasisGeometry
  /// Singular-value labels appear only after the geometry has been seen.
  var showsEffortLabels: Bool

  var body: some View {
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 2.2, duoTopDown: true)
      let matrix = Matrix2(m11: 1, m12: basis.cosine, m21: 0, m22: basis.sine)
      context.drawGrid(mapping, size: size, matrix: matrix, color: Theme.grid)

      if basis.isSingular {
        // Everything collapses onto the one remaining direction.
        var line = Path()
        line.move(to: mapping.point(basis.a2 * -2))
        line.addLine(to: mapping.point(basis.a2 * 2))
        context.stroke(line, with: .color(Theme.warning), style: StrokeStyle(lineWidth: 8, lineCap: .round))
      } else {
        context.drawReachableRegion(basis, in: mapping)
        context.drawMappedCircle(mapping, matrix: matrix, stroke: Theme.neutral, fill: Theme.neutral.opacity(0.05), lineWidth: 2.5)
        let axes = basis.semiaxes
        for (axis, label) in [(axes.major, "easiest"), (axes.minor, "hardest")] {
          var path = Path()
          path.move(to: mapping.point(-axis))
          path.addLine(to: mapping.point(axis))
          context.stroke(path, with: .color(Theme.neutral.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
          if showsEffortLabels, axis.length > 0.12 {
            context.draw(
              Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.neutral.opacity(0.85)),
              at: mapping.point(axis * 1.25)
            )
          }
        }
      }
      context.drawVector(basis.a2, in: mapping, color: Theme.first, lineWidth: 4, label: "a")
      context.drawVector(basis.b2, in: mapping, color: basis.isSingular ? Theme.warning : Theme.second, lineWidth: 4, label: "b")
      context.drawDot(at: mapping.point(.zero), radius: 5, color: Theme.neutral)
    }
    .accessibilityElement()
    .accessibilityLabel("Region reachable with the current basis")
    .accessibilityValue(basis.isSingular ? "Collapsed to a line" : "Area \(basis.determinantMagnitude.fixedText())")
  }
}

/// A one-line physical reading of the reachable region.
struct EffortCaption: View {
  var basis: BasisGeometry

  var body: some View {
    Text(text)
      .font(.title3.weight(.semibold))
      .foregroundStyle(basis.isSingular ? Theme.warning : Theme.neutral)
      .contentTransition(.opacity)
      .animation(Motion.reveal, value: text)
  }

  private var text: String {
    switch basis.quality {
    case .orthonormal, .stable: "Same effort works equally well in every direction."
    case .sensitive: "One direction stays easy. One gets hard."
    case .unstable: "One direction is almost impossible."
    case .singular: "One physical dimension is unreachable."
    }
  }
}
