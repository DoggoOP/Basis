import SwiftUI

/// The outer display's renderer: a projection of the current lesson state.
/// No menus, no controls, one visual idea at a time.
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
    case .matrixImage(let s): OuterMatrixImageView(state: s)
    case .coordinates(let s): OuterCoordinatesView(state: s)
    case .dual(let s): OuterDualView(state: s)
    case .mapImage(let s): OuterMapImageView(state: s)
    case .quantum(let s): OuterQuantumView(state: s)
    case .orientation(let s): OuterOrientationView(state: s)
    }
  }

  private var sceneKind: Int {
    switch state.scene {
    case .none: 0
    case .matrixImage: 1
    case .coordinates: 2
    case .dual: 3
    case .mapImage: 4
    case .quantum: 5
    case .orientation: 6
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
        PanelTitle("Outside · \(title)", tint: tint)
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
      Text("Inside is the construction.\nOutside is the consequence.")
        .font(.system(.title3, design: .serif).italic())
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// B(unit circle): circle at 90°, ellipse when oblique, a segment near singularity.
private struct OuterMatrixImageView: View {
  var state: MatrixImageState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    OuterLayout(title: "B(unit circle)") {
      MatrixImageCanvas(basis: basis, coefficient: nil, showsSigmaLabels: basis.sigmaMin < 0.95)
    } readouts: {
      if basis.isSingular {
        Text("σ₂ → 0   Rank 1")
          .font(.system(.title, design: .serif).weight(.semibold))
          .foregroundStyle(Theme.warning)
      } else {
        ValueRow(label: "σ₁", value: basis.sigmaMax.fixedText())
        ValueRow(label: "σ₂", value: basis.sigmaMin.fixedText())
      }
      Readout(title: "Area scale", tint: Theme.hinge) {
        Text(basis.determinantMagnitude.fixedText())
      }
      QualityLabel(quality: basis.quality)
    }
  }
}

/// Only the representation: c = B⁻¹ p.
private struct OuterCoordinatesView: View {
  var state: CoordinateState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    OuterLayout(title: "Coordinates in Duo basis") {
      VStack(alignment: .leading, spacing: 16) {
        if let c = state.coefficients {
          CoefficientBar(label: "a", value: c.x, tint: Theme.first)
          CoefficientBar(label: "b", value: c.y, tint: Theme.second)
          CoefficientBar(label: "h", value: c.z, tint: Theme.hinge)
        } else {
          CollapsedBasisMessage(title: "Basis collapsed", lines: ["B⁻¹ does not exist", "coordinates are no longer unique"])
        }
      }
      .frame(maxHeight: .infinity)
    } readouts: {
      QualityLabel(quality: basis.quality)
      SensitivityStrip(moved: state.physicalChange, swing: state.coefficientSwing)
    }
  }
}

/// V*: covectors as families of measurement contours around the fixed p.
private struct OuterDualView: View {
  var state: DualState

  var body: some View {
    let basis = BasisGeometry(openingDegrees: state.openingDegrees)
    let dual = DualBasis(basis: basis)
    OuterLayout(title: "Measure", tint: Theme.dual) {
      CovectorContourView(basis: basis, vector: state.vector, isSingular: dual.inverse == nil)
    } readouts: {
      if let c = dual.measure(state.vector) {
        Readout(title: "ω¹(p)", tint: Theme.dual) { Text(c.x.fixedText()) }
        Readout(title: "ω²(p)", tint: Theme.dual) { Text(c.y.fixedText()) }
      } else {
        CollapsedBasisMessage(title: "No dual basis", lines: ["B⁻¹ does not exist"])
      }
    }
  }
}

/// W and im(A).
private struct OuterMapImageView: View {
  var state: MapState

  var body: some View {
    OuterLayout(title: "Codomain W", tint: Theme.second) {
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
    OuterLayout(title: "Outcomes", tint: Theme.dual) {
      VStack(alignment: .leading, spacing: 16) {
        Readout(title: "P(+)", tint: Theme.dual) {
          Text(state.pPlus.percentText())
        }
        MeasurementHistogramView(pPlus: state.pPlus, plusCount: state.plusCount, shotCount: state.shotCount)
      }
      .frame(maxHeight: .infinity)
    } readouts: {
      ShotStreamView(outcomes: state.recentOutcomes)
    }
  }
}

/// The outer face: normal −n, flux −Φ.
private struct OuterOrientationView: View {
  var state: OrientationState

  var body: some View {
    OuterLayout(title: "Outer normal −n", tint: Theme.warning) {
      NormalGlyph(pointsOut: false, tint: Theme.warning)
    } readouts: {
      Readout(title: "Flux Φ₋ₙ", tint: Theme.warning) {
        Text((-state.innerFlux).signedText(fractionDigits: 1))
      }
      Equation("Φ₋ₙ = −Φₙ", revealed: true, tint: .secondary)
    }
  }
}
