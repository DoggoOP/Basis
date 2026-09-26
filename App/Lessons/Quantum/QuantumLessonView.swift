import SwiftUI

/// Act V: the display normals become Bloch measurement axes.
/// Prepare along n_A, measure along n_B: P(+) = (1 + n_A · n_B) / 2.
struct QuantumLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var shots = MeasurementShots()
  @State private var shownShots = 0

  var body: some View {
    let measurement = QuantumMeasurement(openingDegrees: hinge.openingDegrees)
    let plusCount = shots.plusCount(firstShots: shownShots, pPlus: measurement.pPlus)
    let recent = shots.recentOutcomes(shownShots: shownShots, pPlus: measurement.pPlus)
    DualPanelLayout {
      PanelStack(spacing: 16) {
        PanelTitle("Prepare axis n_A", tint: Theme.first)
        BlochAxisView(openingDegrees: hinge.openingDegrees)
        Readout(title: "Angle between axes θ") {
          Text(measurement.normalAngleDegrees.degreesText())
        }
        EquationMorphView()
      }
    } spine: {
      Color.clear
    } trailing: {
      PanelStack(spacing: 16) {
        PanelTitle("Measure axis n_B", tint: Theme.second)
        if outer.usesOuterDisplay {
          // The presenter chooses the axes inside; the outside shows what nature returns.
          Readout(title: "n_A · n_B", tint: Theme.second) {
            Text(measurement.axisDot.signedText())
          }
          Text("Each screen's normal is a Bloch axis. What nature returns is on the outside.")
            .font(.callout)
            .foregroundStyle(.secondary)
        } else {
          Readout(title: "P(+)", tint: Theme.dual) {
            Text(measurement.pPlus.percentText())
          }
          StateBadge(title: measurement.regime.title, tint: Theme.dual)
          Text(measurement.regime.explanation)
            .font(.callout)
            .foregroundStyle(.secondary)
          MeasurementHistogramView(pPlus: measurement.pPlus, plusCount: plusCount, shotCount: shownShots)
          ShotStreamView(outcomes: recent)
        }
        Spacer(minLength: 0)
        Button("Reset Shots", systemImage: "arrow.counterclockwise") {
          shownShots = 0
        }
        .buttonStyle(.bordered)
      }
    }
    .publishesOuterScene(.quantumShots(QuantumState(
      pPlus: measurement.pPlus,
      shotCount: shownShots,
      plusCount: plusCount,
      recentOutcomes: recent
    )))
    .specialMoment(measurement.regime == .unbiased ? .fiftyFifty : nil)
    .task(id: shownShots == 0) {
      // Shots accumulate steadily from the same seeded sequence after every reset.
      while shownShots < MeasurementShots.count {
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 20 : 70))
        if Task.isCancelled { return }
        shownShots += 1
      }
    }
  }
}

/// The two display normals seen from above the hinge, with the angle θ between them.
private struct BlochAxisView: View {
  var openingDegrees: Double

  var body: some View {
    FoldCrossSection(openingDegrees: openingDegrees) { context, frame in
      let length = frame.panelLength * 0.45
      let aMid = frame.leadingPoint(at: 0.5), bMid = frame.trailingPoint(at: 0.5)
      context.drawArrow(from: aMid, to: aMid.offset(by: frame.leadingNormal, scale: length), color: Theme.first, lineWidth: 4, headLength: 12)
      context.drawArrow(from: bMid, to: bMid.offset(by: frame.trailingNormal, scale: length), color: Theme.second, lineWidth: 4, headLength: 12)
      context.draw(
        Text("n_A").font(.system(.callout, design: .serif).italic().weight(.semibold)).foregroundStyle(Theme.first),
        at: aMid.offset(by: frame.leadingNormal, scale: length + 16)
      )
      context.draw(
        Text("n_B").font(.system(.callout, design: .serif).italic().weight(.semibold)).foregroundStyle(Theme.second),
        at: bMid.offset(by: frame.trailingNormal, scale: length + 16)
      )
    }
    .frame(minHeight: 140)
    .accessibilityElement()
    .accessibilityLabel("Display normals n A and n B, viewed from above")
  }
}

/// a · b = cos θ  →  n_A · n_B = cos θ  →  P(+) = (1 + cos θ)/2
private struct EquationMorphView: View {
  @Environment(\.explainsMath) private var explainsMath
  @State private var revealedCount = 0

  private static let lines = ["a · b = cos θ", "n_A · n_B = cos θ", "P(+) = (1 + cos θ) / 2"]

  var body: some View {
    AlignedStack(spacing: 6) {
      ForEach(Self.lines.indices, id: \.self) { index in
        Equation(Self.lines[index], revealed: index < revealedCount, tint: index == revealedCount - 1 ? Theme.neutral : .secondary)
      }
    }
    .task(id: explainsMath) {
      guard explainsMath else {
        revealedCount = 0
        return
      }
      for count in 1...Self.lines.count {
        withAnimation(Motion.reveal) { revealedCount = count }
        try? await Task.sleep(for: .seconds(1.1))
      }
    }
  }
}

/// Theory versus the shots measured so far.
struct MeasurementHistogramView: View {
  var pPlus: Double
  var plusCount: Int
  var shotCount: Int

  var body: some View {
    let measured = shotCount > 0 ? Double(plusCount) / Double(shotCount) : pPlus
    AlignedStack(spacing: 8) {
      bar(symbol: "+", fraction: measured, filled: true)
      bar(symbol: "−", fraction: 1 - measured, filled: false)
      Text("\(shotCount) shots")
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }

  private func bar(symbol: String, fraction: Double, filled: Bool) -> some View {
    HStack(spacing: 12) {
      Text(symbol)
        .font(.title2.weight(.bold))
        .frame(width: 22)
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.white.opacity(0.06))
          Capsule()
            .fill(filled ? AnyShapeStyle(Theme.dual) : AnyShapeStyle(Theme.dual.opacity(0.35)))
            .frame(width: max(proxy.size.width * fraction, 2))
        }
      }
      .frame(height: 16)
      .frame(minWidth: 140)
      Text(fraction.percentText())
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .frame(minWidth: 56, alignment: .trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Outcome \(symbol == "+" ? "plus" : "minus")")
    .accessibilityValue(fraction.percentText())
  }
}

/// The most recent outcomes as a stream of + and − marks.
struct ShotStreamView: View {
  var outcomes: [Bool]

  var body: some View {
    Text(outcomes.map { $0 ? "+" : "−" }.joined(separator: " "))
      .font(.system(.body, design: .monospaced).weight(.semibold))
      .foregroundStyle(Theme.dual)
      .lineLimit(2)
      .frame(minHeight: 44, alignment: .topLeading)
      .accessibilityLabel("Recent shots")
  }
}
