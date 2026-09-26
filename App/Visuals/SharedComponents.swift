import SwiftUI

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

/// Plain-language basis quality: stable, sensitive, or singular.
struct QualityLabel: View {
  var quality: BasisQuality

  var body: some View {
    AlignedStack(spacing: 2) {
      StateBadge(title: quality.title, tint: tint)
      Text(quality.detail)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .animation(Motion.reveal, value: quality)
  }

  private var tint: Color {
    switch quality {
    case .orthonormal, .stable: Theme.hinge
    case .sensitive: Theme.first
    case .unstable, .singular: Theme.warning
    }
  }
}

/// The hinge as an operator boundary between two spaces.
struct MapArrowSpine: View {
  var label: String

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    let layout = edge.isVerticalHinge ? AnyLayout(VStackLayout(spacing: 6)) : AnyLayout(HStackLayout(spacing: 6))
    layout {
      Text(label)
        .font(.system(.title2, design: .serif).weight(.semibold).italic())
        .foregroundStyle(Theme.neutral)
      Image(systemName: edge.isVerticalHinge ? "arrow.right" : "arrow.down")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Maps through \(label)")
  }
}

/// One coordinate as a bar that grows from the center, clipped with a marker when huge.
struct CoefficientBar: View {
  var label: String
  var value: Double
  var tint: Color

  private static let range = 2.0

  var body: some View {
    HStack(spacing: 12) {
      Text(label)
        .font(.system(.title3, design: .serif).weight(.semibold).italic())
        .foregroundStyle(tint)
        .frame(width: 22)
      GeometryReader { proxy in
        let half = proxy.size.width / 2
        let fraction = min(abs(value) / Self.range, 1)
        let width = half * fraction
        ZStack(alignment: .leading) {
          Capsule().fill(Color.white.opacity(0.06))
          Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1).offset(x: half)
          Capsule()
            .fill(tint)
            .frame(width: max(width, 2))
            .offset(x: value >= 0 ? half : half - width)
        }
      }
      .frame(height: 14)
      .frame(minWidth: 120)
      Text(value.signedText())
        .font(.system(.title3, design: .rounded).weight(.semibold))
        .monospacedDigit()
        .frame(minWidth: 72, alignment: .trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Coordinate along \(label)")
    .accessibilityValue(value.signedText())
  }
}

/// Physical change vs coordinate change: ill-conditioning made visceral.
struct SensitivityStrip: View {
  /// |Δp| in meters.
  var moved: Double
  /// Largest coordinate change, or nil when the basis has collapsed.
  var swing: Double?

  var body: some View {
    if moved > 0.0005 {
      HStack(spacing: 24) {
        Readout(title: "Physical change", tint: Theme.probe) {
          Text((moved * 100).fixedText(fractionDigits: 1) + " cm")
        }
        Readout(title: "Coordinate change", tint: Theme.first) {
          Text(swing.map { $0.signedText(fractionDigits: 2) } ?? "—")
        }
      }
      .transition(.opacity)
    }
  }
}

/// The honest replacement for infinite numbers.
struct CollapsedBasisMessage: View {
  var title: String
  var lines: [String]

  var body: some View {
    AlignedStack(spacing: 4) {
      Text(title)
        .font(.title2.weight(.bold))
        .textCase(.uppercase)
        .tracking(1)
        .foregroundStyle(Theme.warning)
      ForEach(lines, id: \.self) { line in
        Text(line)
          .font(.system(.title3, design: .serif).italic())
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

struct ProbeStatusLabel: View {
  var source: PointSourceModel.Source
  var status: HostPeerService.Status

  var body: some View {
    Label(title, systemImage: symbol)
      .font(.footnote.weight(.semibold))
      .foregroundStyle(source == .probe ? Theme.probe : .secondary)
  }

  private var title: String {
    switch source {
    case .frozen: "Vector frozen"
    case .probe: "Probe connected"
    case .preset: status == .searching ? "Preset vector · looking for probe…" : "Preset vector"
    }
  }

  private var symbol: String {
    switch source {
    case .frozen: "pin.fill"
    case .probe: "dot.radiowaves.left.and.right"
    case .preset: "scope"
    }
  }
}

extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

extension SIMD3 where Scalar == Double {
  /// The component with the largest magnitude, keeping its sign.
  var largestComponent: Double {
    [x, y, z].max { abs($0) < abs($1) } ?? 0
  }
}
