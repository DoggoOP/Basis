import SwiftUI

/// Act 1: these two halves are two directions you are allowed to travel, and the hinge
/// gives a third. Coordinates are the travel instructions for reaching a point.
struct DirectionsLessonView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// 0…3 through the a, b, and h legs.
  @State private var progress = 0.0
  /// 0: directions only; 1: route as a combination; 2: compact coordinates.
  @State private var revealStage = 0
  @State private var traceCount = 0

  private static let legDuration = 1.3

  var body: some View {
    let basis = BasisGeometry(openingDegrees: hinge.snappedDegrees)
    let solver = CoordinateSolver(basis: basis, pointWorld: PointSourceModel.presetPoint)
    let coefficients = solver.coefficients
    let route = coefficients.map(CoordinateRoute.init)

    DualPanelLayout {
      ZStack {
        PanelRouteTrack(symbol: "a", amount: route?.amount(.a), progress: CoordinateRoute.legProgress(.a, overall: progress), color: Theme.first)
        PanelStack(spacing: 10) {
          LegInstruction(leg: .a, route: route, hasStarted: progress > 0)
          Spacer()
          RouteReveal(route: route, stage: revealStage)
        }
      }
    } spine: {
      HingeRouteTrack(amount: route?.amount(.h), progress: CoordinateRoute.legProgress(.h, overall: progress))
    } trailing: {
      ZStack {
        PanelRouteTrack(symbol: "b", amount: route?.amount(.b), progress: CoordinateRoute.legProgress(.b, overall: progress), color: Theme.second)
        PanelStack(spacing: 10) {
          LegInstruction(leg: .b, route: route, hasStarted: progress > 1)
          LegInstruction(leg: .h, route: route, hasStarted: progress > 2, isCompact: true)
          Spacer()
          if !outer.usesOuterDisplay {
            MapCard(title: "From above the hinge") {
              RouteMapView(basis: basis, point: solver.pointInDuoFrame, coefficients: coefficients, progress: progress)
            }
          }
          Button(progress >= 3 ? "Trace Again" : "Trace Route", systemImage: "point.topleft.down.to.point.bottomright.curvepath") {
            traceCount += 1
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .specialMoment(SpecialMoment.forBasis(basis))
    .publishesOuterScene(.coordinates(CoordinateState(
      openingDegrees: basis.openingDegrees,
      pointInDuo: solver.pointInDuoFrame,
      coefficients: coefficients,
      progress: progress,
      revealsTuple: revealStage >= 2
    )))
    .task(id: traceCount) {
      await trace(startDelay: traceCount == 0 ? 0.8 : 0.1)
    }
  }

  /// Walks the route one leg at a time, then lets the notation follow the geometry.
  private func trace(startDelay: Double) async {
    revealStage = 0
    progress = 0
    try? await Task.sleep(for: .seconds(startDelay))
    guard !Task.isCancelled else { return }
    if reduceMotion {
      progress = 3
    } else {
      withAnimation(.linear(duration: Self.legDuration * 3)) { progress = 3 }
      try? await Task.sleep(for: .seconds(Self.legDuration * 3))
    }
    guard !Task.isCancelled else { return }
    withAnimation(Motion.reveal) { revealStage = 1 }
    try? await Task.sleep(for: .seconds(1.2))
    guard !Task.isCancelled else { return }
    withAnimation(Motion.reveal) { revealStage = 2 }
  }
}

/// "MOVE ALONG a · 1.4 steps": before tracing it reads "1 unit", the meaning of the arrow.
struct LegInstruction: View {
  var leg: CoordinateRoute.Leg
  var route: CoordinateRoute?
  var hasStarted: Bool
  var isCompact = false

  var body: some View {
    AlignedStack(spacing: 2) {
      PanelTitle(leg == .h ? "Along the hinge h" : "Move along \(leg.symbol)", tint: tint)
      Group {
        if let route, hasStarted {
          Text(route.instruction(for: leg).replacingOccurrences(of: " along \(leg.symbol)", with: ""))
        } else if route == nil {
          Text("No unique route")
        } else {
          Text("1 unit")
        }
      }
      .font(.system(size: isCompact ? 24 : 40, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .contentTransition(.numericText())
      .foregroundStyle(route == nil ? Theme.warning : Theme.neutral)
    }
    .accessibilityElement(children: .combine)
  }

  private var tint: Color {
    switch leg {
    case .a: Theme.first
    case .b: Theme.second
    case .h: Theme.hinge
    }
  }
}

/// Notation arrives only after the route has been traveled:
/// first the route as a combination, then the compact coordinates.
struct RouteReveal: View {
  var route: CoordinateRoute?
  var stage: Int

  var body: some View {
    AlignedStack(spacing: 6) {
      if let route {
        if stage >= 1 {
          PanelTitle("Route")
          Text("p = " + route.linearCombination())
            .font(.system(.title2, design: .serif).italic())
            .monospacedDigit()
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        if stage >= 2 {
          Text("[p]_B = " + route.tuple())
            .font(.system(.title3, design: .serif).italic())
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .transition(.opacity)
        }
      } else {
        CollapsedBasisMessage(title: "No unique route", lines: ["These directions no longer span the space."])
      }
    }
    .animation(Motion.reveal, value: stage)
  }
}

/// A small titled card holding a map-style visualization.
struct MapCard<Content: View>: View {
  var title: String
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      PanelTitle(title)
      content
        .frame(height: 220)
        .frame(maxWidth: 320)
    }
    .padding(12)
    .background(Theme.spine.opacity(0.7), in: .rect(cornerRadius: 18))
  }
}
