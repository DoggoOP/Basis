import SwiftUI

/// Gram–Schmidt removes everything the first direction already explains and asks
/// what genuinely new direction remains.
struct GramSchmidtLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @State private var step = GramSchmidtStep.original
  /// Continuous 0…3 progress through the steps, animated.
  @State private var progress = 0.0

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let gs = GramSchmidt(basis: basis)
    DualPanelLayout {
      PanelStack(spacing: 14) {
        PanelTitle("A = [a b]")
        Text(step.title)
          .font(.title3.weight(.semibold))
          .contentTransition(.opacity)
        ProjectionDecompositionView(basis: basis, progress: progress)
        Equation(stepEquation, revealed: step != .original, tint: .secondary)
      }
    } spine: {
      MapArrowSpine(label: "QR")
    } trailing: {
      PanelStack(spacing: 18) {
        PanelTitle("A = QR")
        MatrixText(name: "R", rows: [[gs.r.r11, gs.r.r12], [0, gs.r.r22]], tint: Theme.neutral)
        Readout(title: "Genuinely new", tint: Theme.hinge) {
          Text(gs.residual.length.fixedText())
        }
        if gs.q2 == nil {
          CollapsedBasisMessage(title: "Nothing new remains", lines: ["R₂₂ = sin α → 0"])
            .transition(.opacity)
        } else if let q2 = gs.q2, step == .normalize {
          MatrixText(name: "Q", rows: [[gs.q1.x, q2.x], [gs.q1.y, q2.y]], tint: Theme.second)
            .transition(.opacity)
        }
        Equation("R₂₂ = sin α", tint: .secondary)
        Spacer(minLength: 0)
        Button(step.next == nil ? "Reset" : "Orthogonalize", systemImage: step.next == nil ? "arrow.counterclockwise" : "perspective") {
          advance()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }
      .animation(Motion.reveal, value: gs.q2 == nil)
    }
    .sensoryFeedback(.selection, trigger: step)
  }

  private var stepEquation: String {
    switch step {
    case .original: "A = [a b]"
    case .keepFirst: "q₁ = a"
    case .removeProjection: "u₂ = b − proj_q₁ b"
    case .normalize: "q₂ = u₂ / ‖u₂‖"
    }
  }

  private func advance() {
    let next = step.next ?? .original
    withAnimation(Motion.step) {
      step = next
      progress = Double(next.rawValue)
    }
  }
}

/// b decomposes into a component along q₁ plus a perpendicular remainder, which normalizes to q₂.
private struct ProjectionDecompositionView: View, Animatable {
  var basis: BasisGeometry
  var progress: Double

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  var body: some View {
    let gs = GramSchmidt(basis: basis)
    let keep = progress.clamped(to: 0...1)
    let remove = (progress - 1).clamped(to: 0...1)
    let normalize = (progress - 2).clamped(to: 0...1)
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 1.35, originOffset: CGSize(width: -size.width * 0.12, height: size.height * 0.18))
      context.drawGrid(mapping, size: size, spacing: 0.25)
      context.drawVector(gs.q1, in: mapping, color: Theme.first, lineWidth: 4 + 2 * keep, label: keep > 0.5 ? "q₁" : "a")
      context.drawVector(basis.b2, in: mapping, color: Theme.second.opacity(1 - 0.6 * remove), label: "b")
      if remove > 0 {
        let projection = gs.projection * remove
        var along = Path()
        along.move(to: mapping.point(.zero))
        along.addLine(to: mapping.point(projection))
        context.stroke(along, with: .color(Theme.first.opacity(0.8)), style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
        let start = gs.projection * (1 - normalize)
        let residual = gs.residual * (1 - normalize) + (gs.q2 ?? gs.residual) * normalize
        context.drawVector(residual, from: start, in: mapping, color: Theme.hinge.opacity(remove), label: normalize > 0.5 ? "q₂" : "u₂")
        if normalize > 0.95, gs.q2 != nil {
          let s = 0.12
          var corner = Path()
          corner.move(to: mapping.point(SIMD2(s, 0)))
          corner.addLine(to: mapping.point(SIMD2(s, s)))
          corner.addLine(to: mapping.point(SIMD2(0, s)))
          context.stroke(corner, with: .color(Theme.neutral.opacity(0.7)), lineWidth: 1.5)
        }
      }
    }
    .accessibilityLabel("Gram–Schmidt decomposition of b")
  }
}
