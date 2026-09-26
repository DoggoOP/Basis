import SwiftUI

/// Maps a mathematical plane (y up) to view coordinates.
struct PlaneMapping {
  var origin: CGPoint
  /// Points per mathematical unit.
  var unit: CGFloat

  /// Centers the origin in `size`, fitting `extent` units between the origin and the nearest edge.
  init(size: CGSize, extent: Double, originOffset: CGSize = .zero) {
    origin = CGPoint(x: size.width / 2 + originOffset.width, y: size.height / 2 + originOffset.height)
    unit = min(size.width, size.height) / 2 / CGFloat(extent)
  }

  init(origin: CGPoint, unit: CGFloat) {
    self.origin = origin
    self.unit = unit
  }

  func point(_ v: SIMD2<Double>) -> CGPoint {
    CGPoint(x: origin.x + CGFloat(v.x) * unit, y: origin.y - CGFloat(v.y) * unit)
  }

  func vector(at point: CGPoint) -> SIMD2<Double> {
    SIMD2(Double((point.x - origin.x) / unit), Double((origin.y - point.y) / unit))
  }
}

extension GraphicsContext {
  /// Draws the images of the integer grid lines under a linear map (identity by default).
  func drawGrid(
    _ mapping: PlaneMapping,
    size: CGSize,
    matrix: Matrix2 = .identity,
    spacing: Double = 0.5,
    color: Color = Theme.grid
  ) {
    let reach = Double(max(size.width, size.height) / mapping.unit) * 1.5
    let count = Int(reach / spacing)
    var path = Path()
    for i in -count...count {
      let k = Double(i) * spacing
      path.move(to: mapping.point(matrix.apply(SIMD2(k, -reach))))
      path.addLine(to: mapping.point(matrix.apply(SIMD2(k, reach))))
      path.move(to: mapping.point(matrix.apply(SIMD2(-reach, k))))
      path.addLine(to: mapping.point(matrix.apply(SIMD2(reach, k))))
    }
    stroke(path, with: .color(color), lineWidth: 1)
  }

  /// Draws the image of the unit circle under `matrix` (a circle, ellipse, or segment).
  func drawMappedCircle(
    _ mapping: PlaneMapping,
    matrix: Matrix2,
    radius: Double = 1,
    stroke color: Color,
    fill fillColor: Color? = nil,
    lineWidth: CGFloat = 3
  ) {
    var path = Path()
    let steps = 120
    for i in 0...steps {
      let t = Double(i) / Double(steps) * 2 * .pi
      let p = mapping.point(matrix.apply(SIMD2(cos(t), sin(t)) * radius))
      i == 0 ? path.move(to: p) : path.addLine(to: p)
    }
    path.closeSubpath()
    if let fillColor { fill(path, with: .color(fillColor)) }
    stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
  }

  func drawVector(
    _ v: SIMD2<Double>,
    from start: SIMD2<Double> = .zero,
    in mapping: PlaneMapping,
    color: Color,
    lineWidth: CGFloat = 4,
    label: String? = nil
  ) {
    let from = mapping.point(start), to = mapping.point(start + v)
    drawArrow(from: from, to: to, color: color, lineWidth: lineWidth, headLength: 14)
    if let label {
      let length = v.length
      let direction = length > 0 ? v / length : SIMD2(1, 0)
      let labelPoint = mapping.point(start + v + direction * Double(18 / mapping.unit))
      draw(
        Text(label).font(.system(.title3, design: .serif).weight(.semibold).italic()).foregroundStyle(color),
        at: labelPoint
      )
    }
  }

  /// Draws a line through `through` in direction `direction`, clipped generously to the view.
  func drawLine(
    through: SIMD2<Double>,
    direction: SIMD2<Double>,
    in mapping: PlaneMapping,
    size: CGSize,
    color: Color,
    lineWidth: CGFloat = 2,
    dash: [CGFloat] = []
  ) {
    let reach = Double(max(size.width, size.height) / mapping.unit) * 1.5
    var path = Path()
    path.move(to: mapping.point(through - direction * reach))
    path.addLine(to: mapping.point(through + direction * reach))
    stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash))
  }

  func drawParallelogram(
    _ u: SIMD2<Double>,
    _ v: SIMD2<Double>,
    in mapping: PlaneMapping,
    color: Color
  ) {
    var path = Path()
    path.move(to: mapping.point(.zero))
    path.addLine(to: mapping.point(u))
    path.addLine(to: mapping.point(u + v))
    path.addLine(to: mapping.point(v))
    path.closeSubpath()
    fill(path, with: .color(color.opacity(0.18)))
    stroke(path, with: .color(color.opacity(0.5)), lineWidth: 1)
  }
}
