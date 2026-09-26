import SwiftUI

/// Act 4: "I know the point. How do I read off how much a and b it contains?"
/// The basis tells you how to travel; the dual basis gives you the rulers that measure.
struct DualityLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer
  @Environment(\.explainsMath) private var explainsMath

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let dual = DualBasis(basis: basis)
    let point3 = PointSourceModel.presetPoint
    let point = BasisGeometry.crossSection(point3)
    let readings = dual.measure(point)

    DualPanelLayout {
      PanelStack(spacing: 14) {
        PanelTitle("Travel", tint: Theme.first)
        Text("a and b tell you how to build P: travel directions.")
          .font(.callout)
          .foregroundStyle(.secondary)
        RouteMapView(
          basis: basis,
          point: point3,
          coefficients: readings.map { SIMD3($0.x, $0.y, point3.y) }
        )
        if let readings {
          Text("P = \(readings.x.fixedText(fractionDigits: 1)) a + \(readings.y.fixedText(fractionDigits: 1)) b")
            .font(.system(.title2, design: .serif).italic())
            .monospacedDigit()
        }
      }
    } spine: {
      MapArrowSpine(label: "ω")
    } trailing: {
      if outer.usesOuterDisplay {
        PanelStack(spacing: 18) {
          PanelTitle("Measure", tint: Theme.dual)
          Text("I know the point. How do I read off how much a and b it contains?")
            .font(.title3.weight(.semibold))
          Text("The rulers are on the outside.")
            .font(.callout)
            .foregroundStyle(.secondary)
          RulerReadings(readings: readings)
          if explainsMath { DualNotation(dual: dual).transition(.opacity) }
          Spacer(minLength: 0)
        }
        .animation(Motion.reveal, value: explainsMath)
      } else {
        PanelStack(spacing: 14) {
          PanelTitle("Measure", tint: Theme.dual)
          DualRulerView(basis: basis, point: point)
          RulerReadings(readings: readings)
          if explainsMath { DualNotation(dual: dual).transition(.opacity) }
        }
        .animation(Motion.reveal, value: explainsMath)
      }
    }
    .publishesOuterScene(.dualRulers(DualState(openingDegrees: basis.openingDegrees, point: point)))
  }
}

/// ωᵃ(P) and ωᵇ(P): what the rulers read at P.
struct RulerReadings: View {
  var readings: SIMD2<Double>?

  var body: some View {
    if let readings {
      HStack(spacing: 24) {
        Readout(title: "Ruler ωᵃ reads", tint: Theme.first) { Text(readings.x.fixedText(fractionDigits: 1)) }
        Readout(title: "Ruler ωᵇ reads", tint: Theme.second) { Text(readings.y.fixedText(fractionDigits: 1)) }
      }
    } else {
      CollapsedBasisMessage(
        title: "No unique rulers",
        lines: ["You cannot tell how much a and how much b produced the point."]
      )
    }
  }
}

/// Revealed last: the rulers are the rows of B⁻¹, and together they form V*.
private struct DualNotation: View {
  var dual: DualBasis

  var body: some View {
    AlignedStack(spacing: 8) {
      if let omega1 = dual.omega1, let omega2 = dual.omega2 {
        MatrixText(name: "B⁻¹", rows: [[omega1.x, omega1.y], [omega2.x, omega2.y]], tint: Theme.dual)
      }
      Equation("ωⁱ(e_j) = δⁱ_j   ·   rulers live in V*", revealed: true, tint: .secondary)
    }
  }
}
