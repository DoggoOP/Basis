import SwiftUI

/// A view of the device from above its hinge: two panel lines meeting at the hinge
/// with opening angle α. The person holding the device is below the diagram.
struct FoldCrossSection: View {
  var openingDegrees: Double
  var decorate: (inout GraphicsContext, FoldFrame) -> Void = { _, _ in }

  var body: some View {
    Canvas { context, size in
      let frame = FoldFrame(size: size, openingDegrees: openingDegrees)
      var panels = Path()
      panels.move(to: frame.leadingPoint(at: 1))
      panels.addLine(to: frame.hinge)
      panels.addLine(to: frame.trailingPoint(at: 1))
      context.stroke(
        panels,
        with: .color(.white.opacity(0.55)),
        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
      )
      decorate(&context, frame)
      context.drawDot(at: frame.hinge, radius: 5, color: Theme.hinge)
    }
    .accessibilityHidden(true)
  }
}

/// Screen geometry of the top-down fold diagram.
struct FoldFrame {
  var hinge: CGPoint
  var panelLength: CGFloat
  /// Unit direction of the leading panel, away from the hinge.
  var leadingDirection: CGVector
  /// Unit direction of the trailing panel, away from the hinge.
  var trailingDirection: CGVector

  init(size: CGSize, openingDegrees: Double) {
    let half = openingDegrees * .pi / 360
    panelLength = min(size.width / 2, size.height) * 0.9
    hinge = CGPoint(x: size.width / 2, y: (size.height - panelLength * cos(half)) / 2)
    leadingDirection = CGVector(dx: -sin(half), dy: cos(half))
    trailingDirection = CGVector(dx: sin(half), dy: cos(half))
  }

  func leadingPoint(at fraction: CGFloat) -> CGPoint {
    hinge.offset(by: leadingDirection, scale: panelLength * fraction)
  }

  func trailingPoint(at fraction: CGFloat) -> CGPoint {
    hinge.offset(by: trailingDirection, scale: panelLength * fraction)
  }

  /// Unit normal of the leading panel's display, pointing into the fold.
  var leadingNormal: CGVector { CGVector(dx: leadingDirection.dy, dy: -leadingDirection.dx) }

  /// Unit normal of the trailing panel's display, pointing into the fold.
  var trailingNormal: CGVector { CGVector(dx: -trailingDirection.dy, dy: trailingDirection.dx) }
}
