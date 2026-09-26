import SwiftUI

/// Act 3: fold the Duo so a and b become almost the same road. The point stays put, but
/// reaching it takes two huge journeys that nearly cancel. That is ill-conditioning.
struct ConditioningLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(HostPeerService.self) private var probeLink
  @Environment(OuterDisplayState.self) private var outer
  @Environment(\.explainsMath) private var explainsMath
  @State private var model = PointSourceModel()

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let probe = PointSourceModel.steps(fromMeters: probeLink.latestVector)
    let solver = CoordinateSolver(basis: basis, pointWorld: model.point(probe: probe))
    let route = solver.coefficients.map(CoordinateRoute.init)
    let straight = solver.pointInDuoFrame.length
    let isPoor = basis.quality == .sensitive || basis.quality == .unstable
    let revealsNumbers = explainsMath || isPoor || basis.isSingular

    DualPanelLayout {
      ZStack {
        PanelRouteTrack(symbol: "a", amount: route?.amount(.a), progress: 1, color: Theme.first)
        PanelStack(spacing: 14) {
          LegInstruction(leg: .a, route: route, hasStarted: true)
          Spacer()
          AlignedStack(spacing: 8) {
            if let route {
              PanelTitle("Same point")
              Text(route.travelLength > straight * 1.6 ? "Longer route" : "Direct route")
                .font(.title.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(route.travelLength > straight * 1.6 ? Theme.first : Theme.hinge)
              HStack(spacing: 24) {
                Readout(title: "Distance traveled") { Text(route.travelLength.fixedText(fractionDigits: 1)) }
                Readout(title: "Straight line") { Text(straight.fixedText(fractionDigits: 1)) }
              }
            } else {
              CollapsedBasisMessage(title: "No unique route", lines: ["These directions no longer span the space."])
            }
          }
          .animation(Motion.reveal, value: route == nil)
        }
      }
    } spine: {
      HingeRouteTrack(amount: route?.amount(.h), progress: 1)
    } trailing: {
      ZStack {
        PanelRouteTrack(symbol: "b", amount: route?.amount(.b), progress: 1, color: Theme.second)
        PanelStack(spacing: 14) {
          LegInstruction(leg: .b, route: route, hasStarted: true)
          if basis.isSingular {
            StateBadge(title: "One dimension lost", tint: Theme.warning)
          } else if isPoor {
            StateBadge(title: "Poorly conditioned", tint: Theme.first)
          }
          if revealsNumbers {
            ConditioningNumbers(basis: basis)
              .transition(.opacity)
          }
          Spacer()
          if outer.usesOuterDisplay {
            MapCard(title: "From above the hinge") {
              RouteMapView(basis: basis, point: solver.pointInDuoFrame, coefficients: solver.coefficients)
            }
          } else {
            MapCard(title: "Reachable with one step each") {
              ReachableRegionView(basis: basis, showsEffortLabels: revealsNumbers)
            }
            EffortCaption(basis: basis)
          }
        }
        .animation(Motion.reveal, value: revealsNumbers)
      }
    }
    .specialMoment(SpecialMoment.forBasis(basis))
    .publishesOuterScene(.reachableRegion(ReachableRegionState(
      openingDegrees: basis.openingDegrees,
      showsNumbers: revealsNumbers
    )))
    .onChange(of: probe) { _, newValue in model.noteProbeReading(newValue) }
    .onAppear { probeLink.start() }
  }
}

/// Revealed only after the geometry has made the idea visible.
struct ConditioningNumbers: View {
  var basis: BasisGeometry

  var body: some View {
    AlignedStack(spacing: 4) {
      if basis.isSingular {
        Text("det B → 0    σ_min → 0")
      } else {
        Text("condition number \(basis.conditionNumber.fixedText(fractionDigits: basis.conditionNumber < 10 ? 2 : 1))")
        Text("|det B| = |sin α| = \(basis.determinantMagnitude.fixedText())")
          .foregroundStyle(.secondary)
      }
    }
    .font(.system(.title3, design: .serif).italic())
    .monospacedDigit()
  }
}
