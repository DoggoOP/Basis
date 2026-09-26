import Foundation
import Observation

/// The judged demo, 90–120 seconds: five acts, one discreet Next button.
enum DemoAct: Int, CaseIterable {
  case directions = 1, holdThePoint, breakTheBasis, rulers, quantum

  var title: String {
    switch self {
    case .directions: "Directions, Not Matrices"
    case .holdThePoint: "Hold the Point"
    case .breakTheBasis: "Break the Basis"
    case .rulers: "The Rulers Behind Coordinates"
    case .quantum: "Quantum Payoff"
    }
  }

  /// What the outer display shows during this act.
  var outerTitle: String {
    switch self {
    case .directions: "Outer = Where it lands"
    case .holdThePoint: "Outer = [P]_B"
    case .breakTheBasis: "Outer = Reachable region"
    case .rulers: "Outer = Dual rulers"
    case .quantum: "Outer = Shots"
    }
  }

  var lab: Lab {
    switch self {
    case .directions: .directions
    case .holdThePoint: .physicalPoint
    case .breakTheBasis: .conditioning
    case .rulers: .duality
    case .quantum: .qubit
    }
  }

  /// Simulated-hinge pose each act starts from, so the presenter never configures live.
  var startingPose: Double {
    switch self {
    case .directions, .holdThePoint, .breakTheBasis, .rulers: 90
    case .quantum: 180
    }
  }
}

@Observable
final class DemoCoordinator {
  private(set) var act = DemoAct.directions
  /// Changing this rebuilds the current act in its preset state.
  private(set) var resetCount = 0

  var isFirstAct: Bool { act.rawValue == 1 }
  var isLastAct: Bool { act.rawValue == DemoAct.allCases.count }

  func next(hinge: HingeModel) {
    guard let next = DemoAct(rawValue: act.rawValue + 1) else { return }
    act = next
    resetAct(hinge: hinge)
  }

  func previous(hinge: HingeModel) {
    guard let previous = DemoAct(rawValue: act.rawValue - 1) else { return }
    act = previous
    resetAct(hinge: hinge)
  }

  func resetAct(hinge: HingeModel) {
    resetCount += 1
    hinge.setSimulatedPose(act.startingPose)
  }
}
