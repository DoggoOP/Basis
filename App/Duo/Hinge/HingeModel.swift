import Foundation
import Observation

/// Single source of truth for the physical opening angle α that every lesson uses.
///
/// α is 0° when closed and 180° when flat. On devices with a hinge it comes from
/// the device; everywhere else a simulated hinge stands in so lessons stay testable.
@Observable
final class HingeModel {
  enum Source {
    case simulated, device
  }

  enum Status {
    case closed, partiallyOpen, fullyOpen
  }

  /// How strongly each new device reading moves the smoothed angle (0…1).
  private static let smoothing = 0.4

  private(set) var source: Source = .simulated
  private(set) var status: Status = .partiallyOpen
  private(set) var openingDegrees: Double = 125
  /// The last raw reading from the device API, kept for calibration checks.
  private(set) var rawDeviceDegrees: Double?

  /// α with the subtle snap to exactly 90° that every lesson displays.
  var snappedDegrees: Double { MathTolerance.snappedOpening(openingDegrees) }

  var isDeviceHingeAvailable: Bool { source == .device }

  /// The nearest mathematically special angle, if α is currently at one.
  var landmark: AngleLandmark? { AngleLandmark(openingDegrees: openingDegrees) }

  /// Drives α from the on-screen stand-in when no hinge is available.
  var simulatedDegrees: Double {
    get { openingDegrees }
    set {
      guard source == .simulated else { return }
      openingDegrees = min(max(newValue, 0), 180)
      status = Self.status(for: openingDegrees)
    }
  }

  /// Feeds a reading from the device hinge, already converted to the opening convention.
  func receiveDeviceReading(openingDegrees reading: Double, rawDegrees: Double, status: Status) {
    rawDeviceDegrees = rawDegrees
    let clamped = min(max(reading, 0), 180)
    if source == .simulated || status != .partiallyOpen {
      openingDegrees = clamped
    } else {
      openingDegrees += (clamped - openingDegrees) * Self.smoothing
    }
    source = .device
    self.status = status
  }

  /// Returns to the simulated hinge, e.g. when the device reports no hinge.
  func useSimulatedHinge() {
    source = .simulated
  }

  /// Jumps the simulated hinge to a demo pose.
  func setSimulatedPose(_ degrees: Double) {
    simulatedDegrees = degrees
  }

  private static func status(for degrees: Double) -> Status {
    switch degrees {
    case ..<1: .closed
    case 179...: .fullyOpen
    default: .partiallyOpen
    }
  }
}

/// Angles with a special mathematical meaning, used for haptics and snapping.
enum AngleLandmark: Equatable {
  case parallel, fortyFive, sixty, orthogonal, oneTwenty, oneThirtyFive, flat

  init?(openingDegrees α: Double) {
    let candidates: [(Self, Double, Double)] = [
      (.parallel, 0, 1),
      (.fortyFive, 45, 1),
      (.sixty, 60, 1),
      (.orthogonal, 90, MathTolerance.orthogonalSnapDegrees),
      (.oneTwenty, 120, 1),
      (.oneThirtyFive, 135, 1),
      (.flat, 180, 1),
    ]
    guard let match = candidates.first(where: { abs(α - $0.1) < $0.2 }) else { return nil }
    self = match.0
  }
}
