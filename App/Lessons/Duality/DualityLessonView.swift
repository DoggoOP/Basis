import SwiftUI

/// Act III: a basis tells you how to build a vector; the dual basis tells you how to measure one.
struct DualityLessonView: View {
  /// The same fixed vector as Change of Basis, seen in the cross-section (x, z).
  static let vector = SIMD2(ChangeOfBasisModel.presetVector.x, ChangeOfBasisModel.presetVector.z)

  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let dual = DualBasis(basis: basis)
    DualPanelLayout {
      BuildPanel(basis: basis, coefficients: dual.measure(Self.vector))
    } spine: {
      MapArrowSpine(label: "ω")
    } trailing: {
      if outer.usesOuterDisplay {
        PrimalBasisPanel(basis: basis)
      } else {
        MeasurePanel(basis: basis, dual: dual, vector: Self.vector)
      }
    }
    .publishesOuterScene(.dual(DualState(openingDegrees: basis.openingDegrees, vector: Self.vector)))
  }
}

/// With the dual grid on the outside, the inside keeps only the primal basis V.
private struct PrimalBasisPanel: View {
  var basis: BasisGeometry

  var body: some View {
    PanelStack(spacing: 18) {
      PanelTitle("Primal space V", tint: Theme.second)
      Readout(title: "Opening angle") {
        Text(basis.openingDegrees.degreesText())
      }
      MatrixText(name: "B", rows: [[1, basis.cosine], [0, basis.sine]])
      Text("The inside tells you how to build the vector. The outside tells you how to measure it.")
        .font(.callout)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
    }
  }
}

/// Primal view: p = c¹a + c²b, built tip to tail from arrows.
private struct BuildPanel: View {
  var basis: BasisGeometry
  var coefficients: SIMD2<Double>?

  var body: some View {
    PanelStack(spacing: 14) {
      PanelTitle("Build", tint: Theme.first)
      Text("A basis tells you how to build a vector.")
        .font(.callout)
        .foregroundStyle(.secondary)
      Canvas { context, size in
        let mapping = PlaneMapping(size: size, extent: 1.1)
        context.drawGrid(mapping, size: size, spacing: 0.25)
        context.drawVector(basis.a2 * 0.8, in: mapping, color: Theme.first, label: "a")
        context.drawVector(basis.b2 * 0.8, in: mapping, color: basis.isSingular ? Theme.warning : Theme.second, label: "b")
        if let c = coefficients {
          context.drawVector(basis.a2 * c.x, in: mapping, color: Theme.first.opacity(0.55), lineWidth: 3)
          context.drawVector(basis.b2 * c.y, from: basis.a2 * c.x, in: mapping, color: Theme.second.opacity(0.55), lineWidth: 3)
        }
        context.drawVector(DualityLessonView.vector, in: mapping, color: Theme.probe, lineWidth: 5, label: "p")
      }
      .accessibilityLabel("p built from a and b")
      if let c = coefficients {
        Text("p = \(c.x.fixedText()) a + \(c.y.fixedText()) b")
          .font(.system(.title3, design: .serif).italic())
          .monospacedDigit()
      }
    }
  }
}

/// Dual view: each covector is a family of level lines, never an arrow.
private struct MeasurePanel: View {
  var basis: BasisGeometry
  var dual: DualBasis
  var vector: SIMD2<Double>

  var body: some View {
    PanelStack(spacing: 14) {
      PanelTitle("Measure", tint: Theme.dual)
      Text("The dual basis tells you how to measure one.")
        .font(.callout)
        .foregroundStyle(.secondary)
      if let omega1 = dual.omega1, let omega2 = dual.omega2, let c = dual.measure(vector) {
        CovectorContourView(basis: basis, vector: vector, isSingular: false)
        HStack(spacing: 24) {
          Readout(title: "ω¹(p)", tint: Theme.dual) { Text(c.x.fixedText()) }
          Readout(title: "ω²(p)", tint: Theme.dual) { Text(c.y.fixedText()) }
        }
        DualSensitivityView(omega1: omega1, omega2: omega2, pairing: dual.pairing)
      } else {
        CovectorContourView(basis: basis, vector: vector, isSingular: true)
        CollapsedBasisMessage(title: "No dual basis", lines: ["B⁻¹ does not exist"])
      }
    }
  }
}

/// Level sets ω¹ = k (lines parallel to b) and ω² = k (lines parallel to a).
struct CovectorContourView: View {
  var basis: BasisGeometry
  var vector: SIMD2<Double>
  var isSingular: Bool

  static let spacing = 0.2
  private static let maximumLines = 180

  var body: some View {
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 1.1)
      if !isSingular {
        let reach = Double(max(size.width, size.height) / mapping.unit)
        // Consecutive ω¹ contours sit sin α apart, so they crowd as the basis collapses.
        let spacingAcross = Self.spacing * abs(basis.sine)
        let count = min(Int(reach / max(spacingAcross, 1e-6)) + 1, Self.maximumLines)
        for i in -count...count {
          let k = Double(i) * Self.spacing
          let emphasis: Double = i == 0 ? 0.9 : 0.45
          context.drawLine(through: basis.a2 * k, direction: basis.b2, in: mapping, size: size, color: Theme.dual.opacity(emphasis), lineWidth: 1.2)
          context.drawLine(through: basis.b2 * k, direction: basis.a2, in: mapping, size: size, color: Theme.dual.opacity(emphasis * 0.7), lineWidth: 1.2, dash: [4, 4])
        }
      } else {
        context.drawLine(through: .zero, direction: basis.a2, in: mapping, size: size, color: Theme.warning.opacity(0.8), lineWidth: 3)
      }
      context.drawVector(vector, in: mapping, color: Theme.probe, lineWidth: 5, label: "p")
    }
    .accessibilityLabel("Dual measurement contours around p")
  }
}

/// The rows of B⁻¹ and the defining property ωⁱ(e_j) = δⁱ_j.
private struct DualSensitivityView: View {
  var omega1: SIMD2<Double>
  var omega2: SIMD2<Double>
  var pairing: [[Double]]?

  @Environment(\.explainsMath) private var explainsMath

  var body: some View {
    AlignedStack(spacing: 8) {
      MatrixText(name: "B⁻¹", rows: [[omega1.x, omega1.y], [omega2.x, omega2.y]], tint: Theme.dual)
      if explainsMath, let pairing {
        MatrixText(name: "ωⁱ(e_j)", rows: pairing, fractionDigits: 0, tint: .secondary)
          .transition(.opacity)
        Equation("rows of B⁻¹ are the dual covectors", tint: .secondary)
      }
    }
    .animation(Motion.reveal, value: explainsMath)
  }
}
