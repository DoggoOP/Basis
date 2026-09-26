import SwiftUI

/// A single slab has opposite oriented normals on its two faces, so flipping the
/// orientation flips the sign of the flux: Φ₋ₙ = −Φₙ.
struct OrientationLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer

  var body: some View {
    let flux = OrientedFlux(openingDegrees: hinge.openingDegrees)
    DualPanelLayout {
      PanelStack(spacing: 14) {
        PanelTitle("Field F", tint: Theme.first)
        Text("A uniform field, fixed to panel A.")
          .font(.callout)
          .foregroundStyle(.secondary)
        FluxCrossSection(openingDegrees: hinge.openingDegrees)
        Equation("Φ = ∬ F · n dA", tint: .secondary)
      }
    } spine: {
      Color.clear
    } trailing: {
      PanelStack(spacing: 18) {
        PanelTitle("Inner normal n", tint: Theme.second)
        NormalGlyph(pointsOut: true, tint: Theme.second)
          .frame(height: 120)
        Readout(title: "Flux Φₙ", tint: Theme.second) {
          Text(flux.innerFlux.signedText(fractionDigits: 1))
        }
        if !outer.usesOuterDisplay {
          Divider()
          PanelTitle("Outer normal −n", tint: Theme.warning)
          Readout(title: "Flux Φ₋ₙ", tint: Theme.warning) {
            Text(flux.outerFlux.signedText(fractionDigits: 1))
          }
          Equation("Φ₋ₙ = −Φₙ", revealed: true, tint: .secondary)
        } else {
          Text("Turn the phone over: the outer face measures the same field with the opposite orientation.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
    }
    .publishesOuterScene(.orientation(OrientationState(innerFlux: flux.innerFlux)))
  }
}

/// ⊙ for a normal pointing out of this screen, ⊗ for one pointing into it.
struct NormalGlyph: View {
  var pointsOut: Bool
  var tint: Color

  var body: some View {
    Canvas { context, size in
      let r = min(size.width, size.height) / 2 * 0.8
      let c = CGPoint(x: size.width / 2, y: size.height / 2)
      let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
      context.stroke(circle, with: .color(tint), lineWidth: 4)
      if pointsOut {
        context.drawDot(at: c, radius: r * 0.22, color: tint)
      } else {
        let d = r * 0.55
        var cross = Path()
        cross.move(to: CGPoint(x: c.x - d, y: c.y - d))
        cross.addLine(to: CGPoint(x: c.x + d, y: c.y + d))
        cross.move(to: CGPoint(x: c.x + d, y: c.y - d))
        cross.addLine(to: CGPoint(x: c.x - d, y: c.y + d))
        context.stroke(cross, with: .color(tint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement()
    .accessibilityLabel(pointsOut ? "Normal pointing out of this screen" : "Normal pointing into this screen")
  }
}

/// From above: field lines along n_A crossing panel B, with both of B's face normals.
private struct FluxCrossSection: View {
  var openingDegrees: Double

  var body: some View {
    FoldCrossSection(openingDegrees: openingDegrees) { context, frame in
      let field = frame.leadingNormal
      let across = CGVector(dx: -field.dy, dy: field.dx)
      let base = frame.leadingPoint(at: 0.5)
      for offset in stride(from: -1.0, through: 1.0, by: 0.5) {
        let start = base
          .offset(by: across, scale: frame.panelLength * 0.35 * offset)
          .offset(by: field, scale: -frame.panelLength * 0.15)
        context.drawArrow(
          from: start,
          to: start.offset(by: field, scale: frame.panelLength * 0.7),
          color: Theme.first.opacity(0.55),
          lineWidth: 2,
          headLength: 9
        )
      }
      let mid = frame.trailingPoint(at: 0.6)
      let length = frame.panelLength * 0.35
      context.drawArrow(from: mid, to: mid.offset(by: frame.trailingNormal, scale: length), color: Theme.second, lineWidth: 4, headLength: 12)
      context.drawArrow(from: mid, to: mid.offset(by: frame.trailingNormal, scale: -length), color: Theme.warning, lineWidth: 4, headLength: 12)
    }
    .frame(minHeight: 160)
    .accessibilityElement()
    .accessibilityLabel("Field lines crossing panel B, with its inner normal and outer normal")
  }
}
