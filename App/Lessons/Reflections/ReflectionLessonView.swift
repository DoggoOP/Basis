import SwiftUI

/// Each panel is a mirror. Two reflections across planes meeting at φ compose into
/// a rotation by 2φ about their intersection, which is the hinge.
struct ReflectionLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @State private var order: [ReflectionComposition.Mirror] = [.a, .b]
  @State private var appliedCount = 0

  var body: some View {
    let composition = ReflectionComposition(openingDegrees: hinge.snappedDegrees)
    let rotation = composition.rotationDegrees(first: order[0], second: order[1])
    DualPanelLayout {
      PanelStack(spacing: 14) {
        PanelTitle("From above the hinge")
        RotationCompositionView(composition: composition, order: order, appliedCount: appliedCount)
      }
    } spine: {
      Color.clear
    } trailing: {
      PanelStack(spacing: 18) {
        PanelTitle("Mirror planes")
        HStack(spacing: 24) {
          Readout(title: "Mirror angle φ") {
            Text(composition.mirrorAngleDegrees.degreesText())
          }
          Readout(title: "Rotation 2φ", tint: Theme.hinge) {
            Text(abs(rotation).degreesText())
          }
        }
        if appliedCount == 2 {
          AlignedStack(spacing: 4) {
            Text("= Rotate \(abs(rotation).degreesText(fractionDigits: 0)) about hinge")
              .font(.title3.weight(.bold))
              .textCase(.uppercase)
              .foregroundStyle(Theme.hinge)
            Text(order == [.a, .b] ? "R_B R_A" : "R_A R_B")
              .font(.system(.title3, design: .serif).italic())
              .foregroundStyle(.secondary)
          }
          .transition(.opacity)
        }
        if let n = composition.cyclicOrder {
          CyclicOrbitView(order: n, stepDegrees: 360 / Double(n))
            .transition(.opacity)
        }
        Spacer(minLength: 0)
        controls
      }
      .animation(Motion.reveal, value: appliedCount)
      .animation(Motion.reveal, value: composition.cyclicOrder)
    }
    .sensoryFeedback(.selection, trigger: appliedCount)
  }

  private var controls: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        ForEach(order, id: \.self) { mirror in
          Button(mirror == .a ? "Reflect A" : "Reflect B") {
            withAnimation(Motion.step) { appliedCount += 1 }
          }
          .buttonStyle(.borderedProminent)
          .tint(mirror == .a ? Theme.first : Theme.second)
          .foregroundStyle(.black)
          .disabled(nextMirror != mirror)
        }
      }
      HStack(spacing: 10) {
        Button("Swap Order", systemImage: "arrow.left.arrow.right") {
          withAnimation(Motion.step) { order.reverse() }
        }
        Button("Reset", systemImage: "arrow.counterclockwise") {
          withAnimation(Motion.step) { appliedCount = 0 }
        }
        .disabled(appliedCount == 0)
      }
      .buttonStyle(.bordered)
    }
  }

  private var nextMirror: ReflectionComposition.Mirror? {
    appliedCount < 2 ? order[appliedCount] : nil
  }
}

/// A flag in the cross-section, its mirror images, and the single arc that replaces them.
private struct RotationCompositionView: View {
  var composition: ReflectionComposition
  var order: [ReflectionComposition.Mirror]
  var appliedCount: Int

  /// An asymmetric flag, so reflections are visibly orientation-reversing.
  private static let flag: [SIMD2<Double>] = [
    SIMD2(0.08, 0.35), SIMD2(0.08, 0.8), SIMD2(0.42, 0.68), SIMD2(0.08, 0.56),
  ]

  var body: some View {
    Canvas { context, size in
      let unit = min(size.width, size.height) / 2 * 0.85
      let hinge = CGPoint(x: size.width / 2, y: size.height / 2)
      func point(_ v: SIMD2<Double>) -> CGPoint {
        CGPoint(x: hinge.x + CGFloat(v.x) * unit, y: hinge.y + CGFloat(v.y) * unit)
      }

      for mirror in [ReflectionComposition.Mirror.a, .b] {
        let u = composition.direction(of: mirror)
        let color = mirror == .a ? Theme.first : Theme.second
        var extended = Path()
        extended.move(to: point(-u * 0.9))
        extended.addLine(to: point(u * 1.1))
        context.stroke(extended, with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 6]))
        var panel = Path()
        panel.move(to: hinge)
        panel.addLine(to: point(u))
        context.stroke(panel, with: .color(color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        context.draw(
          Text(mirror == .a ? "A" : "B").font(.headline).foregroundStyle(color),
          at: point(u * 1.08)
        )
      }

      let flag = Self.flag
      func drawFlag(_ points: [SIMD2<Double>], color: Color, filled: Bool) {
        var pole = Path()
        pole.move(to: point(points[0]))
        pole.addLine(to: point(points[1]))
        context.stroke(pole, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        var cloth = Path()
        cloth.move(to: point(points[1]))
        cloth.addLine(to: point(points[2]))
        cloth.addLine(to: point(points[3]))
        cloth.closeSubpath()
        filled ? context.fill(cloth, with: .color(color)) : context.stroke(cloth, with: .color(color), lineWidth: 2)
      }

      drawFlag(flag, color: Theme.neutral, filled: true)
      var current = flag
      for index in 0..<appliedCount {
        let mirror = order[index]
        current = current.map { composition.reflect($0, across: mirror) }
        let isFinal = index == 1
        drawFlag(current, color: (mirror == .a ? Theme.first : Theme.second).opacity(isFinal ? 1 : 0.55), filled: isFinal)
      }

      if appliedCount == 2 {
        let rotation = composition.rotationDegrees(first: order[0], second: order[1]).degreesToRadians
        let radius = flag[2].length
        let start = atan2(flag[2].y, flag[2].x)
        var arc = Path()
        let steps = 48
        for i in 0...steps {
          let t = start + rotation * Double(i) / Double(steps)
          let p = point(SIMD2(cos(t), sin(t)) * radius)
          i == 0 ? arc.move(to: p) : arc.addLine(to: p)
        }
        context.stroke(arc, with: .color(Theme.hinge), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 6]))
        let endAngle = start + rotation
        let end = point(SIMD2(cos(endAngle), sin(endAngle)) * radius)
        context.drawDot(at: end, radius: 5, color: Theme.hinge)
      }
      context.drawDot(at: hinge, radius: 6, color: Theme.hinge)
    }
    .accessibilityElement()
    .accessibilityLabel("Flag reflected across the panel mirrors")
    .accessibilityValue(appliedCount == 2 ? "Composed into a rotation about the hinge" : "\(appliedCount) reflections applied")
  }
}

/// When φ = π/n, repeating the rotation n times returns to the identity.
private struct CyclicOrbitView: View {
  var order: Int
  var stepDegrees: Double

  var body: some View {
    AlignedStack(spacing: 4) {
      PanelTitle("Cyclic group of order \(order)")
      let names = ["I"] + (1..<order).map { "R\(Int((stepDegrees * Double($0)).rounded()))" } + ["I"]
      Text(names.joined(separator: " → "))
        .font(.system(.body, design: .rounded).weight(.semibold))
        .foregroundStyle(Theme.hinge)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }
  }
}
