import SwiftUI

/// a lives on panel A, b on panel B, and a × b lies along their physical intersection.
struct PhysicalDirectionsView: View {
  /// Shows a reveal button when set; otherwise B is already revealed (its image is outside).
  var revealMatrix: (() -> Void)?

  @Environment(HingeModel.self) private var hinge
  @State private var isSwapped = false

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    DualPanelLayout {
      ZStack {
        PanelDirectionArrow(label: "a", color: Theme.first)
        PanelStack(spacing: 18) {
          PanelTitle("Panel A", tint: Theme.first)
          Readout(title: "Opening angle") {
            Text(basis.openingDegrees.degreesText())
          }
          AlignedStack(spacing: 6) {
            if basis.isOrthogonal {
              StateBadge(title: "Orthogonal", tint: Theme.hinge)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            Equation("a · b = 0", revealed: basis.isOrthogonal)
          }
          .animation(Motion.reveal, value: basis.isOrthogonal)
          Spacer()
        }
      }
    } spine: {
      CrossProductIndicator(direction: basis.isSingular ? 0 : (isSwapped ? -1 : 1), magnitude: basis.determinantMagnitude, isSwapped: isSwapped)
    } trailing: {
      ZStack {
        PanelDirectionArrow(label: "b", color: Theme.second)
        PanelStack(spacing: 18) {
          PanelTitle("Panel B", tint: Theme.second)
          Readout(title: isSwapped ? "|b × a|" : "|a × b|", tint: Theme.hinge) {
            Text(basis.determinantMagnitude.fixedText(fractionDigits: 2))
          }
          Equation("along the hinge", revealed: true, tint: .secondary)
          Spacer()
          Button("Swap Order", systemImage: "arrow.left.arrow.right") {
            withAnimation(Motion.step) { isSwapped.toggle() }
          }
          .buttonStyle(.bordered)
          if let revealMatrix {
            Button("Reveal B = [a b]", systemImage: "square.grid.2x2", action: revealMatrix)
              .buttonStyle(.borderedProminent)
          } else {
            MatrixText(name: "B", rows: [[1, basis.cosine], [0, basis.sine]])
            Text("Its image is on the outside.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .sensoryFeedback(.selection, trigger: isSwapped)
  }
}

/// A unit direction drawn from the hinge outward, lying in its panel.
struct PanelDirectionArrow: View {
  var label: String
  var color: Color

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    Canvas { context, size in
      let panel = PanelGeometry(size: size, edge: edge)
      let length = min(panel.depth * 0.72, 320)
      let start = panel.point(away: 10, along: 0)
      let end = panel.point(away: length, along: 0)
      context.drawArrow(from: start, to: end, color: color, lineWidth: 6, headLength: 22)
      context.draw(
        Text(label).font(.system(size: 34, weight: .semibold, design: .serif).italic()).foregroundStyle(color),
        at: panel.point(away: length * 0.55, along: 30)
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Vector \(label), pointing away from the hinge")
  }
}

/// a × b drawn along the hinge; its direction flips with the order of the product.
struct CrossProductIndicator: View {
  /// +1 along h, −1 against it, 0 when the product vanishes.
  var direction: Double
  var magnitude: Double
  var isSwapped: Bool

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    Canvas { context, size in
      let vertical = edge.isVerticalHinge
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let span = (vertical ? size.height : size.width) * 0.3
      let h = vertical ? CGVector(dx: 0, dy: -1) : CGVector(dx: 1, dy: 0)

      var line = Path()
      line.move(to: center.offset(by: h, scale: -span * 1.4))
      line.addLine(to: center.offset(by: h, scale: span * 1.4))
      context.stroke(line, with: .color(Theme.hinge.opacity(0.25)), style: StrokeStyle(lineWidth: 2, dash: [4, 6]))

      guard direction != 0 else { return }
      let end = center.offset(by: h, scale: span * magnitude * direction)
      context.drawArrow(from: center, to: end, color: Theme.hinge, lineWidth: 5, headLength: 16)
      let labelPoint = end.offset(by: h, scale: direction * 22)
      context.draw(
        Text(isSwapped ? "b×a" : "a×b").font(.system(.caption, design: .serif).weight(.bold).italic()).foregroundStyle(Theme.hinge),
        at: labelPoint
      )
    }
    .accessibilityElement()
    .accessibilityLabel(isSwapped ? "b cross a" : "a cross b")
    .accessibilityValue(direction == 0 ? "Zero" : (direction > 0 ? "Points up along the hinge" : "Points down along the hinge"))
  }
}
