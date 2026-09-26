import SwiftUI

extension GraphicsContext {
  /// Strokes a line with a filled arrowhead at `end`.
  func drawArrow(
    from start: CGPoint,
    to end: CGPoint,
    color: Color,
    lineWidth: CGFloat = 5,
    headLength: CGFloat = 18
  ) {
    let dx = end.x - start.x, dy = end.y - start.y
    let length = (dx * dx + dy * dy).squareRoot()
    guard length > 0.5 else { return }
    let ux = dx / length, uy = dy / length
    let head = min(headLength, length)
    let base = CGPoint(x: end.x - ux * head, y: end.y - uy * head)

    var shaft = Path()
    shaft.move(to: start)
    shaft.addLine(to: base)
    stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

    let halfWidth = head * 0.55
    var tip = Path()
    tip.move(to: end)
    tip.addLine(to: CGPoint(x: base.x - uy * halfWidth, y: base.y + ux * halfWidth))
    tip.addLine(to: CGPoint(x: base.x + uy * halfWidth, y: base.y - ux * halfWidth))
    tip.closeSubpath()
    fill(tip, with: .color(color))
  }

  func drawDot(at point: CGPoint, radius: CGFloat, color: Color) {
    fill(
      Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
      with: .color(color)
    )
  }

  func drawLabel(_ text: Text, at point: CGPoint, anchor: UnitPoint = .center) {
    draw(text, at: point, anchor: anchor)
  }
}

extension CGPoint {
  func offset(by vector: CGVector, scale: CGFloat) -> CGPoint {
    CGPoint(x: x + vector.dx * scale, y: y + vector.dy * scale)
  }
}
