import Foundation
import Observation

/// One rehearsable step of the judged demo.
enum DemoStep: Int, CaseIterable {
  case phoneIsMatrix, singularValues, changeOfBasis, duality, maps, quantum

  var act: DemoAct {
    switch self {
    case .phoneIsMatrix, .singularValues: .matrix
    case .changeOfBasis: .coordinates
    case .duality: .duality
    case .maps: .maps
    case .quantum: .quantum
    }
  }

  /// Simulated-hinge pose the step starts from, so the presenter never configures live.
  var startingPose: Double {
    switch self {
    case .phoneIsMatrix: 120
    case .singularValues: 90
    case .changeOfBasis: 90
    case .duality: 90
    case .maps: 90
    case .quantum: 180
    }
  }
}

enum DemoAct: Int, CaseIterable {
  case matrix = 1, coordinates, duality, maps, quantum

  var title: String {
    switch self {
    case .matrix: "Phone = Matrix"
    case .coordinates: "Change the Basis"
    case .duality: "Dual Space"
    case .maps: "Maps Between Spaces"
    case .quantum: "Quantum"
    }
  }

  /// What the outer display shows during this act.
  var outerTitle: String {
    switch self {
    case .matrix: "Outer = Image"
    case .coordinates: "Outer = Coordinates"
    case .duality: "Outer = Measurement"
    case .maps: "Outer = Codomain"
    case .quantum: "Outer = Outcomes"
    }
  }

  var lab: Lab {
    switch self {
    case .matrix: .matrix
    case .coordinates: .coordinates
    case .duality: .duality
    case .maps: .maps
    case .quantum: .qubit
    }
  }
}

/// Linear sequence for judging: one discreet Next button advances through the acts.
@Observable
final class DemoCoordinator {
  private(set) var step = DemoStep.phoneIsMatrix
  /// Changing this rebuilds the current act in its preset state.
  private(set) var resetCount = 0

  var act: DemoAct { step.act }
  var isLastStep: Bool { step.rawValue == DemoStep.allCases.count - 1 }
  var isFirstStep: Bool { step.rawValue == 0 }

  var matrixStage: MatrixStage {
    step == .phoneIsMatrix ? .directions : .transform
  }

  func next(hinge: HingeModel) {
    guard let next = DemoStep(rawValue: step.rawValue + 1) else { return }
    move(to: next, hinge: hinge)
  }

  func previous(hinge: HingeModel) {
    guard let previous = DemoStep(rawValue: step.rawValue - 1) else { return }
    move(to: previous, hinge: hinge)
  }

  func resetAct(hinge: HingeModel) {
    resetCount += 1
    hinge.setSimulatedPose(step.startingPose)
  }

  func start(hinge: HingeModel) {
    step = .phoneIsMatrix
    resetAct(hinge: hinge)
  }

  private func move(to newStep: DemoStep, hinge: HingeModel) {
    let changesAct = newStep.act != step.act
    step = newStep
    if changesAct {
      resetAct(hinge: hinge)
    } else {
      hinge.setSimulatedPose(newStep.startingPose)
    }
  }
}
