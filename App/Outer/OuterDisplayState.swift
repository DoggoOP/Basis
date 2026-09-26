import Foundation
import Observation

/// Shared state for the outer render target. The lesson owns the math; this only
/// records which scene to project and whether the outer display can show it.
@Observable
final class OuterDisplayState {
  enum Mode: String, CaseIterable, Identifiable {
    /// Use the outer display whenever the system makes it available.
    case automatic
    /// Keep everything on the inner display, using each lesson's fallback layout.
    case innerOnly

    var id: Self { self }

    var title: String {
      switch self {
      case .automatic: "Automatic"
      case .innerOnly: "Inner Only"
      }
    }
  }

  /// Which system path is driving the outer display.
  enum Path: String {
    case externalAccessory = "External accessory"
    case cameraAccessory = "Camera capture accessory"
    case none = "None (requires iOS 27)"
  }

  private static let modeKey = "outerDisplayMode"
  private static let previewKey = "showsOuterPreview"

  var scene = OuterScene.none
  /// Reported by the scene accessory's availability callback.
  var isAvailable = false
  var path = Path.none

  var mode: Mode = Mode(rawValue: UserDefaults.standard.string(forKey: modeKey) ?? "") ?? .automatic {
    didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
  }

  /// Developer-only floating preview of the outer scene on the inner display.
  var showsPreview = UserDefaults.standard.bool(forKey: previewKey) {
    didSet { UserDefaults.standard.set(showsPreview, forKey: Self.previewKey) }
  }

  var isPresented: Bool { scene != .none && usesOuterDisplay }

  /// Lessons move their consequence panel outside only when this is true.
  var usesOuterDisplay: Bool { isAvailable && mode == .automatic }
}

/// Lesson code talks to the outer display only through this protocol, so it never
/// depends on one accessory API.
protocol OuterDisplayPresenting {
  func present(_ scene: OuterScene)
  func dismiss()
}

struct OuterDisplayCoordinator: OuterDisplayPresenting {
  var state: OuterDisplayState

  func present(_ scene: OuterScene) {
    if state.scene != scene { state.scene = scene }
  }

  func dismiss() {
    state.scene = .none
  }
}
