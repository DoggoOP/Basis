import SwiftUI

/// Folding changes where the surface lives in space, not the geometry experienced on it.
struct IntrinsicExtrinsicView: View {
  @Environment(HingeModel.self) private var hinge
  @State private var pointA = SurfacePoint(distanceFromHinge: 170, alongHinge: 0)
  @State private var pointB = SurfacePoint(distanceFromHinge: 170, alongHinge: 0)

  var body: some View {
    let geometry = SurfaceGeometry(a: pointA, b: pointB, openingDegrees: hinge.openingDegrees)
    DualPanelLayout {
      ZStack {
        SurfacePointCanvas(point: $pointA, label: "A", color: Theme.first, crossingAlong: geometry.hingeCrossingAlong)
        PanelStack(spacing: 12) {
          Readout(title: "Surface distance", tint: Theme.hinge) {
            Text(millimeters(geometry.surfaceDistance))
          }
          Text("Along the screens. Folding never changes it.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .allowsHitTesting(false)
      }
    } spine: {
      Color.clear
    } trailing: {
      ZStack {
        SurfacePointCanvas(point: $pointB, label: "B", color: Theme.second, crossingAlong: geometry.hingeCrossingAlong)
        PanelStack(spacing: 12) {
          Readout(title: "Through space", tint: Theme.probe) {
            Text(millimeters(geometry.spatialDistance))
          }
          Text("A straight line through the air.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
          FoldCrossSection(openingDegrees: hinge.openingDegrees) { context, frame in
            let depth = max(pointA.distanceFromHinge, pointB.distanceFromHinge, 1)
            let a = frame.leadingPoint(at: pointA.distanceFromHinge / depth)
            let b = frame.trailingPoint(at: pointB.distanceFromHinge / depth)
            var chord = Path()
            chord.move(to: a)
            chord.addLine(to: b)
            context.stroke(chord, with: .color(Theme.probe), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            context.drawDot(at: a, radius: 6, color: Theme.first)
            context.drawDot(at: b, radius: 6, color: Theme.second)
          }
          .frame(width: 200, height: 120)
          Equation("c² = a² + b² − 2ab cos α", tint: .secondary)
        }
        .allowsHitTesting(false)
      }
    }
  }

  private func millimeters(_ points: Double) -> String {
    (points * SurfaceGeometry.millimetersPerPoint).formatted(.number.precision(.fractionLength(0))) + " mm"
  }
}

/// A draggable point on one panel, with its half of the shortest surface path to the hinge.
private struct SurfacePointCanvas: View {
  @Binding var point: SurfacePoint
  var label: String
  var color: Color
  var crossingAlong: Double

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    GeometryReader { proxy in
      let panel = PanelGeometry(size: proxy.size, edge: edge)
      Canvas { context, _ in
        let location = panel.point(away: point.distanceFromHinge, along: point.alongHinge)
        let crossing = panel.point(away: 0, along: crossingAlong)
        var path = Path()
        path.move(to: location)
        path.addLine(to: crossing)
        context.stroke(path, with: .color(Theme.hinge.opacity(0.8)), style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
        context.drawDot(at: crossing, radius: 4, color: Theme.hinge)
        context.drawDot(at: location, radius: 14, color: color)
        context.draw(Text(label).font(.headline).foregroundStyle(.black), at: location)
      }
      .contentShape(.rect)
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          let c = panel.coordinates(of: value.location)
          point = SurfacePoint(
            distanceFromHinge: Double(c.away.clamped(to: 16...(panel.depth - 16))),
            alongHinge: Double(c.along.clamped(to: -(panel.span / 2 - 16)...(panel.span / 2 - 16)))
          )
        }
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Point \(label)")
    .accessibilityValue("\((point.distanceFromHinge * SurfaceGeometry.millimetersPerPoint).formatted(.number.precision(.fractionLength(0)))) millimeters from the hinge")
    .accessibilityAdjustableAction { direction in
      point.distanceFromHinge = (point.distanceFromHinge + (direction == .increment ? 12 : -12)).clamped(to: 16...600)
    }
  }
}
