import SwiftUI

/// The outer display's renderer: a projection of the current lesson state.
/// No menus, no controls, one visual idea at a time, legible from several feet away.
struct OuterSceneView: View {
  var state: OuterDisplayState

  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()
      content
        .padding(20)
    }
    .preferredColorScheme(.dark)
    .environment(\.hingeEdge, .trailing)
    .animation(Motion.reveal, value: sceneKind)
  }

  @ViewBuilder
  private var content: some View {
    switch state.scene {
    case .none: OuterIdleView()
    case .coordinates(let s): OuterCoordinatesView(state: s)
    case .reachableRegion(let s): OuterReachableRegionView(state: s)
    case .dualRulers(let s): OuterDualRulersView(state: s)
    case .mapImage(let s): OuterMapImageView(state: s)
    case .quantumShots(let s): OuterQuantumView(state: s)
    case .flux(let s): OuterFluxView(state: s)
    }
  }

  private var sceneKind: Int {
    switch state.scene {
    case .none: 0
    case .coordinates: 1
    case .reachableRegion: 2
    case .dualRulers: 3
    case .mapImage: 4
    case .quantumShots: 5
    case .flux: 6
    }
  }
}

/// Lays out a hero visual beside or above its readouts, depending on the outer display's shape.
private struct OuterLayout<Visual: View, Readouts: View>: View {
  var title: String
  var tint: Color = .secondary
  @ViewBuilder var visual: Visual
  @ViewBuilder var readouts: Readouts

  var body: some View {
    GeometryReader { proxy in
      let isWide = proxy.size.width > proxy.size.height * 1.15
      VStack(alignment: .leading, spacing: 12) {
        PanelTitle(title, tint: tint)
        if isWide {
          HStack(spacing: 20) {
            visual.frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 14) { readouts }
              .frame(maxWidth: proxy.size.width * 0.42, alignment: .leading)
          }
        } else {
          visual.frame(maxWidth: .infinity, maxHeight: .infinity)
          VStack(alignment: .leading, spacing: 14) { readouts }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
}

private struct OuterIdleView: View {
  var body: some View {
    VStack(spacing: 8) {
      Text("Basis")
        .font(.largeTitle.weight(.bold))
        .textCase(.uppercase)
        .tracking(3)
      Text("Math you can hold.")
        .font(.system(.title3, design: .serif).italic())
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Where the route lands, and [P]_B once the route has been traveled.
private struct OuterCoordinatesView: View {
  var state: CoordinateState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    OuterLayout(title: "Where the route lands") {
      RouteMapView(basis: basis, point: state.pointInDuo, coefficients: state.coefficients, progress: state.progress)
    } readouts: {
      if let c = state.coefficients {
        if state.revealsTuple {
          AlignedStack(spacing: 2) {
            Text("[P]_B")
              .font(.system(.title3, design: .serif).italic())
              .foregroundStyle(.secondary)
            Text(CoordinateRoute(coefficients: c).tuple(fractionDigits: 2))
              .font(.system(size: 40, weight: .semibold, design: .rounded))
              .monospacedDigit()
              .minimumScaleFactor(0.5)
              .lineLimit(1)
              .contentTransition(.numericText())
          }
          .transition(.opacity)
        }
      } else {
        CollapsedBasisMessage(title: "No unique route", lines: ["These directions no longer span the space."])
      }
    }
  }
}

/// The reachable region squashes as the basis folds, and collapses to a line at singularity.
private struct OuterReachableRegionView: View {
  var state: ReachableRegionState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    OuterLayout(title: "What this basis can reach", tint: Theme.hinge) {
      ReachableRegionView(basis: basis, showsEffortLabels: state.showsNumbers)
    } readouts: {
      if basis.isSingular {
        Text("One Dimension Lost")
          .font(.title.weight(.bold))
          .textCase(.uppercase)
          .foregroundStyle(Theme.warning)
      }
      EffortCaption(basis: basis)
      if state.showsNumbers {
        ConditioningNumbers(basis: basis)
          .transition(.opacity)
      }
    }
  }
}

/// The dual rulers that read how much a and b a point contains.
private struct OuterDualRulersView: View {
  var state: DualState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    OuterLayout(title: "Dual rulers", tint: Theme.dual) {
      DualRulerView(basis: basis, point: state.point)
    } readouts: {
      RulerReadings(readings: DualBasis(basis: basis).measure(state.point))
    }
  }
}

/// Output space W and im(A).
private struct OuterMapImageView: View {
  var state: MapState

  var body: some View {
    OuterLayout(title: "Output space W", tint: Theme.second) {
      CodomainView(matrix: state.matrix, x: state.x, showsImage: state.showsLabels)
        .animation(Motion.morph, value: state.matrix)
    } readouts: {
      MapPropertiesView(matrix: state.matrix, isRevealed: state.showsLabels)
    }
  }
}

/// What nature returns.
private struct OuterQuantumView: View {
  var state: QuantumState

  var body: some View {
    OuterLayout(title: "Measurement shots", tint: Theme.dual) {
      VStack(alignment: .leading, spacing: 16) {
        ShotStreamView(outcomes: state.recentOutcomes)
        MeasurementHistogramView(pPlus: state.pPlus, plusCount: state.plusCount, shotCount: state.shotCount)
      }
      .frame(maxHeight: .infinity)
    } readouts: {
      Readout(title: "P(+)", tint: Theme.dual) {
        Text(state.pPlus.percentText())
      }
    }
  }
}

/// The outer face: normal −n, flux −Φ.
private struct OuterFluxView: View {
  var state: FluxState

  var body: some View {
    OuterLayout(title: "Outer normal −n", tint: Theme.warning) {
      NormalGlyph(pointsOut: false, tint: Theme.warning)
    } readouts: {
      Readout(title: "Flux", tint: Theme.warning) {
        Text((-state.innerFlux).signedText(fractionDigits: 1))
      }
      Equation("Φ₋ₙ = −Φₙ", revealed: true, tint: .secondary)
    }
  }
}
