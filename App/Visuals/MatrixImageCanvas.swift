import simd
import SwiftUI

/// B(unit circle): the skewed grid, the spanned parallelogram, the ellipse, and its SVD axes.
struct MatrixImageCanvas: View {
  var basis: BasisGeometry
  /// A coefficient on the unit circle whose image is traced on the ellipse.
  var coefficient: SIMD2<Double>?
  var showsSigmaLabels: Bool
  var showsBasisVectors = true

  var body: some View {
    let matrix = Matrix2(m11: 1, m12: basis.cosine, m21: 0, m22: basis.sine)
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 1.7)
      context.drawGrid(mapping, size: size, matrix: matrix, color: Theme.grid)
      context.drawParallelogram(basis.a2, basis.b2, in: mapping, color: Theme.hinge)
      context.drawMappedCircle(mapping, matrix: matrix, stroke: basis.isSingular ? Theme.warning : Theme.neutral, fill: Theme.neutral.opacity(0.06))
      let axes = basis.semiaxes
      for (axis, label) in [(axes.major, "σ₁"), (axes.minor, "σ₂")] {
        var path = Path()
        path.move(to: mapping.point(-axis))
        path.addLine(to: mapping.point(axis))
        context.stroke(path, with: .color(Theme.neutral.opacity(0.45)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
        if showsSigmaLabels, axis.length > 0.08 {
          context.draw(
            Text(label).font(.system(.callout, design: .serif).italic()).foregroundStyle(Theme.neutral.opacity(0.8)),
            at: mapping.point(axis * 1.15)
          )
        }
      }
      if showsBasisVectors {
        context.drawVector(basis.a2, in: mapping, color: Theme.first, label: "a")
        context.drawVector(basis.b2, in: mapping, color: Theme.second, label: "b")
      }
      if let coefficient {
        context.drawDot(at: mapping.point(basis.B2 * coefficient), radius: 7, color: Theme.neutral)
      }
    }
    .accessibilityElement()
    .accessibilityLabel("Image of the unit circle under B")
    .accessibilityValue("Singular values \(basis.sigmaMax.fixedText()) and \(basis.sigmaMin.fixedText())")
  }
}
