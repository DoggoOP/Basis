import SwiftUI

/// Act 2: instead of drawing the point, hold it. The probe iPhone is P. Rotating the whole
/// Duo changes the frame's orientation, so the same fixed point gets new travel instructions.
struct PhysicalPointLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(HostPeerService.self) private var probeLink
  @Environment(OuterDisplayState.self) private var outer
  @Environment(DuoAttitudeProvider.self) private var attitude
  @State private var model = PointSourceModel()
  /// Coordinates captured before the frame was rotated, for a before/after comparison.
  @State private var before: CoordinateRoute?

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let probe = PointSourceModel.steps(fromMeters: probeLink.latestVector)
    let point = model.point(probe: probe)
    let solver = CoordinateSolver(basis: basis, pointWorld: point, frameYaw: attitude.yawRadians)
    let route = solver.coefficients.map(CoordinateRoute.init)
    let isStill = model.physicalChange(probe: probe).length < 0.01

    DualPanelLayout {
      ZStack {
        PanelRouteTrack(symbol: "a", amount: route?.amount(.a), progress: 1, color: Theme.first)
        PanelStack(spacing: 14) {
          AlignedStack(spacing: 4) {
            StateBadge(title: isStill ? "Point P is fixed" : "P is moving", tint: isStill ? Theme.hinge : Theme.probe)
              .animation(Motion.reveal, value: isStill)
            ProbeStatusLabel(source: model.source(probe: probe), status: probeLink.status)
          }
          RouteInstructions(route: route)
          Spacer()
          if let before, let route {
            BeforeAfterView(before: before, after: route)
              .transition(.opacity)
          }
        }
      }
      // Panel A carries the frame: its attitude is the Duo's orientation.
      .definesMotionBody(for: attitude)
    } spine: {
      HingeRouteTrack(amount: route?.amount(.h), progress: 1)
    } trailing: {
      ZStack {
        PanelRouteTrack(symbol: "b", amount: route?.amount(.b), progress: 1, color: Theme.second)
        PanelStack(spacing: 14) {
          FrameChangeCard(attitude: attitude) { isEditing in
            if isEditing, before == nil { before = route }
          }
          Spacer()
          if !outer.usesOuterDisplay {
            MapCard(title: "From above the hinge") {
              RouteMapView(basis: basis, point: solver.pointInDuoFrame, coefficients: solver.coefficients)
            }
          }
          controls(probe: probe, route: route)
        }
      }
    }
    .animation(Motion.reveal, value: before == nil)
    .specialMoment(SpecialMoment.forBasis(basis))
    .publishesOuterScene(.coordinates(CoordinateState(
      openingDegrees: basis.openingDegrees,
      pointInDuo: solver.pointInDuoFrame,
      coefficients: solver.coefficients,
      progress: 3,
      revealsTuple: true
    )))
    .onChange(of: probe) { _, newValue in model.noteProbeReading(newValue) }
    .onAppear {
      probeLink.start()
      attitude.start()
    }
    .onDisappear { attitude.stop() }
  }

  private func controls(probe: SIMD3<Double>?, route: CoordinateRoute?) -> some View {
    HStack(spacing: 10) {
      Toggle(
        "Leave P Here",
        systemImage: model.isFrozen ? "pin.fill" : "pin",
        isOn: Binding { model.isFrozen } set: { _ in model.toggleFreeze(probe: probe) }
      )
      .toggleStyle(.button)
      Button("Mark Before", systemImage: "camera.metering.center.weighted") {
        before = route
      }
      Button("Reset Frame", systemImage: "arrow.counterclockwise") {
        attitude.resetReference()
        before = nil
      }
    }
    .buttonStyle(.bordered)
  }
}

/// "ROUTE USING THIS BASIS · +0.42 along a …"
struct RouteInstructions: View {
  var route: CoordinateRoute?

  var body: some View {
    AlignedStack(spacing: 6) {
      PanelTitle("Route using this basis")
      if let route {
        ForEach(CoordinateRoute.Leg.allCases) { leg in
          HStack(spacing: 10) {
            Text(route.amount(leg).signedText())
              .font(.system(.title, design: .rounded).weight(.semibold))
              .monospacedDigit()
              .contentTransition(.numericText())
              .frame(minWidth: 96, alignment: .trailing)
            Text("along \(leg.symbol)")
              .font(.system(.title3, design: .serif).italic())
              .foregroundStyle(color(leg))
          }
          .accessibilityElement(children: .combine)
        }
      } else {
        CollapsedBasisMessage(title: "No unique route", lines: ["These directions no longer span the space."])
      }
    }
  }

  private func color(_ leg: CoordinateRoute.Leg) -> Color {
    switch leg {
    case .a: Theme.first
    case .b: Theme.second
    case .h: Theme.hinge
    }
  }
}

/// The point didn't move; only the frame did.
private struct BeforeAfterView: View {
  var before: CoordinateRoute
  var after: CoordinateRoute

  var body: some View {
    AlignedStack(spacing: 4) {
      PanelTitle("Same point")
      Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
        GridRow {
          Text("Before").foregroundStyle(.secondary)
          Text(before.tuple(fractionDigits: 2)).monospacedDigit()
        }
        GridRow {
          Text("Now").foregroundStyle(.secondary)
          Text(after.tuple(fractionDigits: 2)).monospacedDigit().foregroundStyle(Theme.neutral)
        }
      }
      .font(.system(.body, design: .rounded).weight(.semibold))
      Text("The point didn't move. The frame did, so the numbers changed.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }
}

/// Fold changes the basis shape; rotate changes its orientation.
private struct FrameChangeCard: View {
  @Bindable var attitude: DuoAttitudeProvider
  var onEditingChanged: (Bool) -> Void

  var body: some View {
    AlignedStack(spacing: 10) {
      Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
        GridRow {
          Text("Fold").font(.headline).textCase(.uppercase)
          Text("changes basis shape").foregroundStyle(.secondary)
        }
        GridRow {
          Text("Rotate").font(.headline).textCase(.uppercase)
          Text("changes basis orientation").foregroundStyle(.secondary)
        }
      }
      .font(.callout)
      switch attitude.source {
      case .waitingForSensor:
        Label("Reading device motion…", systemImage: "gyroscope")
          .font(.callout)
          .foregroundStyle(.secondary)
      case .continuousSensor:
        Readout(title: "Frame rotation · sensed", tint: Theme.hinge) {
          Text(attitude.yawDegrees.degreesText(fractionDigits: 0))
        }
      case .simulatedControl:
        VStack(alignment: .leading, spacing: 4) {
          Slider(
            value: $attitude.simulatedYawDegrees,
            in: -90...90,
            label: { Text("Frame rotation") },
            minimumValueLabel: { Text("−90°") },
            maximumValueLabel: { Text("+90°") },
            onEditingChanged: onEditingChanged
          )
          Text("Demo control: this device can't sense whole-frame rotation. Rotation \(attitude.yawDegrees.degreesText(fractionDigits: 0))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 320)
      }
    }
    .onChange(of: attitude.yawDegrees) { old, new in
      // Capture "before" as soon as a sensed rotation begins.
      if attitude.isSensed, abs(old) < 1, abs(new) >= 1 { onEditingChanged(true) }
    }
  }
}
