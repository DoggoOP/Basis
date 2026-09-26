import SwiftUI

/// Act II: coordinates are not vectors. p stays fixed; the basis changes; c = B⁻¹ p changes.
struct ChangeOfBasisView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(HostPeerService.self) private var probeLink
  @Environment(OuterDisplayState.self) private var outer
  @State private var model = ChangeOfBasisModel()

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let probe = probeLink.latestVector
    let p = model.vector(probe: probe)
    let solve = ChangeOfBasis(basis: basis, vector: p)
    let physicalChange = model.physicalChange(probe: probe)
    let coefficientChange = solve.coefficientChange(for: physicalChange)
    DualPanelLayout {
      ProbeVectorPanel(model: model, basis: basis, vector: p, coefficients: solve.coefficients, probe: probe)
    } spine: {
      MapArrowSpine(label: "B⁻¹")
    } trailing: {
      CoordinateBarsPanel(
        model: model,
        basis: basis,
        coefficients: solve.coefficients,
        physicalChange: physicalChange,
        coefficientChange: coefficientChange,
        probe: probe,
        showsCoordinates: !outer.usesOuterDisplay
      )
    }
    .publishesOuterScene(.coordinates(CoordinateState(
      openingDegrees: basis.openingDegrees,
      coefficients: solve.coefficients,
      physicalChange: physicalChange.length,
      coefficientSwing: coefficientChange?.largestComponent
    )))
    .onChange(of: probe) { _, newValue in model.noteProbeReading(newValue) }
    .onAppear { probeLink.start() }
  }
}

/// The fixed physical vector, in meters, with the basis it is being described in.
private struct ProbeVectorPanel: View {
  var model: ChangeOfBasisModel
  var basis: BasisGeometry
  var vector: SIMD3<Double>
  var coefficients: SIMD3<Double>?
  var probe: SIMD3<Double>?

  @Environment(HostPeerService.self) private var probeLink

  var body: some View {
    let isUnchanged = model.physicalChange(probe: probe).length < 0.0005
    PanelStack(spacing: 14) {
      PanelTitle("Physical vector p", tint: Theme.probe)
      ProbeStatusLabel(source: model.source(probe: probe), status: probeLink.status)
      AlignedStack(spacing: 4) {
        ValueRow(label: "x", value: vector.x.signedText() + " m")
        ValueRow(label: "y", value: vector.y.signedText() + " m")
        ValueRow(label: "z", value: vector.z.signedText() + " m")
      }
      StateBadge(title: isUnchanged ? "Unchanged" : "Moved", tint: isUnchanged ? Theme.hinge : Theme.probe)
        .animation(Motion.reveal, value: isUnchanged)
      CrossSectionCanvas(model: model, basis: basis, vector: vector, coefficients: coefficients, isDraggable: model.source(probe: probe) == .preset)
    }
  }
}

/// The x–z cross-section: a, b, and p, with p built tip-to-tail from its coordinates.
private struct CrossSectionCanvas: View {
  var model: ChangeOfBasisModel
  var basis: BasisGeometry
  var vector: SIMD3<Double>
  var coefficients: SIMD3<Double>?
  var isDraggable: Bool

  private static let extent = 1.2

  var body: some View {
    GeometryReader { proxy in
      let mapping = PlaneMapping(size: proxy.size, extent: Self.extent)
      let p = SIMD2(vector.x, vector.z)
      Canvas { context, size in
        context.drawGrid(mapping, size: size, spacing: 0.25)
        if let c = coefficients {
          let along = basis.a2 * c.x
          var path = Path()
          path.move(to: mapping.point(.zero))
          path.addLine(to: mapping.point(along))
          context.stroke(path, with: .color(Theme.first.opacity(0.7)), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
          var second = Path()
          second.move(to: mapping.point(along))
          second.addLine(to: mapping.point(along + basis.b2 * c.y))
          context.stroke(second, with: .color(Theme.second.opacity(0.7)), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        }
        context.drawVector(basis.a2 * 0.8, in: mapping, color: Theme.first, label: "a")
        context.drawVector(basis.b2 * 0.8, in: mapping, color: basis.isSingular ? Theme.warning : Theme.second, label: "b")
        context.drawVector(p, in: mapping, color: Theme.probe, lineWidth: 5, label: "p")
      }
      .contentShape(.rect)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            guard isDraggable else { return }
            let v = mapping.vector(at: value.location)
            model.setManualCrossSection(x: v.x.clamped(to: -1.1...1.1), z: v.y.clamped(to: -1.1...1.1))
          },
        isEnabled: isDraggable
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Cross-section of p and the Duo basis")
    .accessibilityHint(isDraggable ? "Drag to place p" : "")
  }
}

/// Coefficient bars for (a, b, h), the sensitivity strip, and the singular guard.
private struct CoordinateBarsPanel: View {
  var model: ChangeOfBasisModel
  var basis: BasisGeometry
  var coefficients: SIMD3<Double>?
  var physicalChange: SIMD3<Double>
  var coefficientChange: SIMD3<Double>?
  var probe: SIMD3<Double>?
  /// False when the coordinates are shown on the outer display instead.
  var showsCoordinates: Bool

  var body: some View {
    PanelStack(spacing: 18) {
      PanelTitle(showsCoordinates ? "Coordinates in Duo basis" : "Changing basis B(α)")
      Readout(title: "Opening angle") {
        Text(basis.openingDegrees.degreesText())
      }
      if !showsCoordinates {
        QualityLabel(quality: basis.quality)
        Text("The vector is here. Its coordinates are on the outside.")
          .font(.callout)
          .foregroundStyle(.secondary)
      } else if let c = coefficients {
        AlignedStack(spacing: 10) {
          CoefficientBar(label: "a", value: c.x, tint: Theme.first)
          CoefficientBar(label: "b", value: c.y, tint: Theme.second)
          CoefficientBar(label: "h", value: c.z, tint: Theme.hinge)
        }
        .transition(.opacity)
        Equation("c = B⁻¹ p", tint: .secondary)
      } else {
        CollapsedBasisMessage(
          title: "Basis collapsed",
          lines: ["B⁻¹ does not exist", "coordinates are no longer unique"]
        )
        .transition(.opacity)
      }
      if showsCoordinates {
        SensitivityStrip(moved: physicalChange.length, swing: coefficientChange.map(\.largestComponent))
      }
      Spacer(minLength: 0)
      controls
    }
    .animation(Motion.reveal, value: coefficients == nil)
  }

  @ViewBuilder
  private var controls: some View {
    HStack(spacing: 10) {
      Toggle(
        "Freeze Vector",
        systemImage: model.isFrozen ? "pin.fill" : "pin",
        isOn: Binding { model.isFrozen } set: { _ in model.toggleFreeze(probe: probe) }
      )
      .toggleStyle(.button)
      .buttonStyle(.bordered)
      if model.source(probe: probe) == .preset {
        Button("Nudge 6 mm", systemImage: "hand.point.up.left") { model.nudge() }
          .buttonStyle(.bordered)
      } else {
        Button("Mark", systemImage: "scope") { model.markReference(probe: probe) }
          .buttonStyle(.bordered)
      }
    }
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
  var source: ChangeOfBasisModel.Source
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
