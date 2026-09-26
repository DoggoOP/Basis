import SwiftUI

/// Visual length of one step of travel on a panel, in points.
private func stepLength(for panel: PanelGeometry) -> CGFloat {
  min(panel.depth * 0.22, 110)
}

/// One leg of a route drawn on its own physical panel: the unit direction starts at the
/// hinge, tiles mark each step, and a glowing tracer travels the leg's distance.
/// Negative amounts travel backward, shown with chevrons pointing back toward the hinge.
struct PanelRouteTrack: View, Animatable {
  var symbol: String
  /// Signed steps along this direction; nil when no unique route exists.
  var amount: Double?
  /// 0…1 progress along this leg.
  var progress: Double
  var color: Color

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    Canvas { context, size in
      let panel = PanelGeometry(size: size, edge: edge)
      let step = stepLength(for: panel)
      let maxTrail = panel.depth - 36
      let across = CGVector(dx: panel.hingeDirection.dx, dy: panel.hingeDirection.dy)

      // Tiles: one tick per step of travel.
      var ticks = Path()
      var k: CGFloat = 1
      while k * step < maxTrail {
        let p = panel.point(away: k * step, along: 0)
        ticks.move(to: p.offset(by: across, scale: -9))
        ticks.addLine(to: p.offset(by: across, scale: 9))
        k += 1
      }
      var axis = Path()
      axis.move(to: panel.point(away: 0, along: 0))
      axis.addLine(to: panel.point(away: maxTrail, along: 0))
      context.stroke(axis, with: .color(color.opacity(0.18)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
      context.stroke(ticks, with: .color(color.opacity(0.35)), lineWidth: 2)

      // The traveled trail.
      if let amount, progress > 0 {
        let fullLength = CGFloat(abs(amount)) * step
        let length = min(fullLength * CGFloat(progress), maxTrail)
        var trail = Path()
        trail.move(to: panel.point(away: 0, along: 0))
        trail.addLine(to: panel.point(away: length, along: 0))
        context.stroke(trail, with: .color(color.opacity(amount < 0 ? 0.18 : 0.3)), style: StrokeStyle(lineWidth: 16, lineCap: .round))
        // Chevrons show which way the traveler moves.
        let spacing: CGFloat = 26
        var d = spacing / 2
        while d < length - 4 {
          let center = panel.point(away: d, along: 0)
          let pointsAway: CGFloat = amount < 0 ? -1 : 1
          let tip = center.offset(by: panel.awayDirection, scale: 5 * pointsAway)
          var chevron = Path()
          chevron.move(to: tip.offset(by: panel.awayDirection, scale: -8 * pointsAway).offset(by: across, scale: -6))
          chevron.addLine(to: tip)
          chevron.addLine(to: tip.offset(by: panel.awayDirection, scale: -8 * pointsAway).offset(by: across, scale: 6))
          context.stroke(chevron, with: .color(color.opacity(0.9)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
          d += spacing
        }
        let end = panel.point(away: length, along: 0)
        if progress < 1 {
          context.drawDot(at: end, radius: 14, color: Theme.probe.opacity(0.25))
          context.drawDot(at: end, radius: 7, color: Theme.probe)
        }
        if progress >= 1, fullLength > maxTrail {
          context.draw(
            Text("×\(Int((fullLength / maxTrail).rounded(.up))) longer →").font(.caption.weight(.bold)).foregroundStyle(color),
            at: panel.point(away: maxTrail - 40, along: -30)
          )
        }
      }

      // The unit direction itself: "move one unit this way".
      context.drawArrow(from: panel.point(away: 4, along: 0), to: panel.point(away: step, along: 0), color: color, lineWidth: 6, headLength: 18)
      context.draw(
        Text(symbol).font(.system(size: 30, weight: .semibold, design: .serif).italic()).foregroundStyle(color),
        at: panel.point(away: step * 0.55, along: 30)
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Direction \(symbol)")
    .accessibilityValue(amount.map { "\($0.fixedText(fractionDigits: 1)) steps" } ?? "No unique route")
  }
}

/// The hinge leg: travel along h, which runs along the physical fold.
struct HingeRouteTrack: View, Animatable {
  var amount: Double?
  var progress: Double

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    Canvas { context, size in
      let vertical = edge.isVerticalHinge
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let h = vertical ? CGVector(dx: 0, dy: -1) : CGVector(dx: 1, dy: 0)
      let span = (vertical ? size.height : size.width) / 2 - 20
      let step = min(span * 0.4, 110)

      var line = Path()
      line.move(to: center.offset(by: h, scale: -span))
      line.addLine(to: center.offset(by: h, scale: span))
      context.stroke(line, with: .color(Theme.hinge.opacity(0.25)), style: StrokeStyle(lineWidth: 2, dash: [3, 5]))

      if let amount, progress > 0 {
        let length = min(CGFloat(abs(amount)) * step * CGFloat(progress), span)
        let direction: CGFloat = amount < 0 ? -1 : 1
        var trail = Path()
        trail.move(to: center)
        trail.addLine(to: center.offset(by: h, scale: length * direction))
        context.stroke(trail, with: .color(Theme.hinge.opacity(0.35)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        if progress < 1 {
          context.drawDot(at: center.offset(by: h, scale: length * direction), radius: 7, color: Theme.probe)
        }
      }
      context.drawArrow(from: center, to: center.offset(by: h, scale: step), color: Theme.hinge, lineWidth: 4, headLength: 12)
      context.drawDot(at: center, radius: 7, color: Theme.neutral)
      context.draw(
        Text("h").font(.system(.title3, design: .serif).weight(.semibold).italic()).foregroundStyle(Theme.hinge),
        at: center.offset(by: h, scale: step + 18)
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Hinge direction h; the origin sits on the hinge")
    .accessibilityValue(amount.map { "\($0.fixedText(fractionDigits: 1)) steps" } ?? "")
  }
}
