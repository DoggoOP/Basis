import SwiftUI

/// The Duo seen from above its hinge: panel A (fixed, pointing left), panel B (folding toward
/// you), the target P, and the route that reaches it tip to tail. The view zooms out as the
/// route grows, so near singularity you see two long journeys that almost cancel.
struct RouteMapView: View, Animatable {
  var basis: BasisGeometry
  /// The point in the Duo frame, in steps.
  var point: SIMD3<Double>
  /// Nil when the directions no longer span the space.
  var coefficients: SIMD3<Double>?
  /// 0…3 progress through the a, b, and h legs.
  var progress: Double = 3
  var showsRegion = false

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  var body: some View {
    let p = BasisGeometry.crossSection(point)
    let firstLeg = coefficients.map { basis.a2 * $0.x } ?? .zero
    let secondLeg = coefficients.map { basis.b2 * $0.y } ?? .zero
    let reach = max(1.6, p.length, firstLeg.length, (firstLeg + secondLeg).length)
    let extent = min(reach * 1.25, 14)

    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: extent, duoTopDown: true)
      context.drawGrid(mapping, size: size, spacing: extent > 6 ? 2 : 1)

      if showsRegion, !basis.isSingular {
        context.drawReachableRegion(basis, in: mapping)
      }

      // The two panels as physical lines from the hinge.
      let panelLength = extent * 1.6
      for (direction, color) in [(basis.a2, Theme.first), (basis.b2, Theme.second)] {
        var panel = Path()
        panel.move(to: mapping.point(.zero))
        panel.addLine(to: mapping.point(direction * panelLength))
        context.stroke(panel, with: .color(color.opacity(0.28)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
      }
      if basis.isSingular {
        context.drawLine(through: .zero, direction: basis.a2, in: mapping, size: size, color: Theme.warning.opacity(0.8), lineWidth: 2, dash: [6, 5])
      }
      context.drawVector(basis.a2, in: mapping, color: Theme.first, lineWidth: 4, label: "a")
      context.drawVector(basis.b2, in: mapping, color: Theme.second, lineWidth: 4, label: "b")

      // The route, tip to tail.
      if coefficients != nil {
        let t1 = CoordinateRoute.legProgress(.a, overall: progress)
        let t2 = CoordinateRoute.legProgress(.b, overall: progress)
        let end1 = firstLeg * t1
        routeSegment(&context, from: .zero, to: end1, color: Theme.first, mapping: mapping)
        let end2 = firstLeg + secondLeg * t2
        if t2 > 0 { routeSegment(&context, from: firstLeg, to: end2, color: Theme.second, mapping: mapping) }
        if progress < 3 {
          let tracer = t2 > 0 ? end2 : end1
          context.drawDot(at: mapping.point(tracer), radius: 12, color: Theme.probe.opacity(0.25))
          context.drawDot(at: mapping.point(tracer), radius: 6, color: Theme.probe)
        }
      }

      context.drawDot(at: mapping.point(.zero), radius: 6, color: Theme.neutral)
      context.drawDot(at: mapping.point(p), radius: 9, color: Theme.probe)
      context.draw(
        Text("P").font(.system(.headline, design: .serif).italic()).foregroundStyle(Theme.probe),
        at: mapping.point(p).offset(by: CGVector(dx: 0, dy: -1), scale: 20)
      )
      if let h = coefficients?.z, progress > 2 {
        context.draw(
          Text("\(h >= 0 ? "↑" : "↓") \(abs(h).fixedText(fractionDigits: 1)) h").font(.caption.weight(.semibold)).foregroundStyle(Theme.hinge),
          at: mapping.point(p).offset(by: CGVector(dx: 1, dy: 0), scale: 36)
        )
      }

      // Scale bar, so zooming out still reads as "longer route".
      let bar = mapping.unit
      let barStart = CGPoint(x: 16, y: size.height - 16)
      var scale = Path()
      scale.move(to: barStart)
      scale.addLine(to: CGPoint(x: barStart.x + bar, y: barStart.y))
      context.stroke(scale, with: .color(Theme.neutral.opacity(0.6)), lineWidth: 2)
      context.draw(Text("1 step").font(.caption2).foregroundStyle(.secondary), at: CGPoint(x: barStart.x + bar / 2, y: barStart.y - 10))
    }
    .accessibilityElement()
    .accessibilityLabel("Map from above the hinge showing the route to P")
    .accessibilityValue(coefficients.map { CoordinateRoute(coefficients: $0).linearCombination() } ?? "No unique route")
  }

  private func routeSegment(_ context: inout GraphicsContext, from: SIMD2<Double>, to: SIMD2<Double>, color: Color, mapping: PlaneMapping) {
    var path = Path()
    path.move(to: mapping.point(from))
    path.addLine(to: mapping.point(to))
    context.stroke(path, with: .color(color.opacity(0.9)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
  }
}

extension GraphicsContext {
  /// Everything reachable with |c_a| ≤ 1 and |c_b| ≤ 1: the parallelogram with corners ±a ± b.
  func drawReachableRegion(_ basis: BasisGeometry, in mapping: PlaneMapping, opacity: Double = 1) {
    let a = basis.a2, b = basis.b2
    var region = Path()
    region.move(to: mapping.point(a + b))
    region.addLine(to: mapping.point(a - b))
    region.addLine(to: mapping.point(-a - b))
    region.addLine(to: mapping.point(-a + b))
    region.closeSubpath()
    fill(region, with: .color(Theme.hinge.opacity(0.14 * opacity)))
    stroke(region, with: .color(Theme.hinge.opacity(0.55 * opacity)), lineWidth: 1.5)
  }
}
