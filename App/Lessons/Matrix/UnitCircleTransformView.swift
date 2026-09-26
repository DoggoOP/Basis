import simd
import SwiftUI

/// Coefficient space → physical space. The unit circle of coefficients maps to an
/// ellipse whose semiaxes are the singular values of the physical basis.
struct UnitCircleTransformView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let phase = reduceMotion ? .pi / 4 : timeline.date.timeIntervalSinceReferenceDate * 0.7
      let coefficient = SIMD2(cos(phase), sin(phase))
      DualPanelLayout {
        CoefficientSpacePanel(basis: basis, coefficient: coefficient)
      } spine: {
        MapArrowSpine(label: "B")
      } trailing: {
        PhysicalSpacePanel(basis: basis, coefficient: coefficient)
      }
    }
  }
}

private struct CoefficientSpacePanel: View {
  var basis: BasisGeometry
  var coefficient: SIMD2<Double>

  var body: some View {
    PanelStack(spacing: 16) {
      PanelTitle("Coefficient space")
      Text("unit circle of c")
        .font(.system(.title3, design: .serif).italic())
        .foregroundStyle(.secondary)
      Canvas { context, size in
        let mapping = PlaneMapping(size: size, extent: 1.7)
        context.drawGrid(mapping, size: size)
        context.drawMappedCircle(mapping, matrix: .identity, stroke: Theme.neutral, fill: Theme.neutral.opacity(0.06))
        context.drawVector(SIMD2(1, 0), in: mapping, color: Theme.first.opacity(0.8), lineWidth: 3, label: "e₁")
        context.drawVector(SIMD2(0, 1), in: mapping, color: Theme.second.opacity(0.8), lineWidth: 3, label: "e₂")
        context.drawDot(at: mapping.point(coefficient), radius: 7, color: Theme.neutral)
      }
      .accessibilityLabel("Unit circle in coefficient space")
      MatrixText(name: "B", rows: [[1, basis.cosine], [0, basis.sine]])
      Equation("p = B c", revealed: true, tint: .secondary)
    }
  }
}

private struct PhysicalSpacePanel: View {
  var basis: BasisGeometry
  var coefficient: SIMD2<Double>

  @Environment(\.explainsMath) private var explainsMath

  /// Singular-value labels appear only after the ellipse has visibly stretched.
  private var showsSigmaLabels: Bool { explainsMath || basis.sigmaMin < 0.95 }

  var body: some View {
    let matrix = Matrix2(m11: 1, m12: basis.cosine, m21: 0, m22: basis.sine)
    PanelStack(spacing: 16) {
      PanelTitle("Physical space")
      HStack(alignment: .top, spacing: 24) {
        Readout(title: "Area scale", tint: Theme.hinge) {
          Text(basis.determinantMagnitude.fixedText(fractionDigits: 2))
        }
        Readout(title: "Basis quality", tint: basis.isSingular ? Theme.warning : .secondary) {
          Text(basis.isSingular ? "—" : "κ " + basis.conditionNumber.fixedText(fractionDigits: basis.conditionNumber < 10 ? 2 : 1))
        }
      }
      QualityLabel(quality: basis.quality)
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
        context.drawVector(basis.a2, in: mapping, color: Theme.first, label: "a")
        context.drawVector(basis.b2, in: mapping, color: Theme.second, label: "b")
        context.drawDot(at: mapping.point(basis.B2 * coefficient), radius: 7, color: Theme.neutral)
      }
      .accessibilityLabel("Ellipse in physical space")
      .accessibilityValue("Singular values \(basis.sigmaMax.fixedText()) and \(basis.sigmaMin.fixedText())")
      AlignedStack(spacing: 6) {
        if basis.isSingular {
          Text("σ₂ → 0   RANK 1")
            .font(.system(.title3, design: .serif).weight(.semibold))
            .foregroundStyle(Theme.warning)
        } else {
          ValueRow(label: "σ₁", value: basis.sigmaMax.fixedText())
          ValueRow(label: "σ₂", value: basis.sigmaMin.fixedText())
        }
      }
      .opacity(showsSigmaLabels || basis.isSingular ? 1 : 0)
      .animation(Motion.reveal, value: showsSigmaLabels)
      Equation("κ = σ₁ / σ₂", tint: .secondary)
    }
  }
}

/// Plain-language basis quality: stable, sensitive, or singular.
struct QualityLabel: View {
  var quality: BasisQuality

  var body: some View {
    AlignedStack(spacing: 2) {
      StateBadge(title: quality.title, tint: tint)
      Text(quality.detail)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .animation(Motion.reveal, value: quality)
  }

  private var tint: Color {
    switch quality {
    case .orthonormal, .stable: Theme.hinge
    case .sensitive: Theme.first
    case .unstable, .singular: Theme.warning
    }
  }
}

/// The hinge as an operator boundary between two spaces.
struct MapArrowSpine: View {
  var label: String

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    let layout = edge.isVerticalHinge ? AnyLayout(VStackLayout(spacing: 6)) : AnyLayout(HStackLayout(spacing: 6))
    layout {
      Text(label)
        .font(.system(.title2, design: .serif).weight(.semibold).italic())
        .foregroundStyle(Theme.neutral)
      Image(systemName: edge.isVerticalHinge ? "arrow.right" : "arrow.down")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Maps through \(label)")
  }
}
