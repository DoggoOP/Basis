import SwiftUI

extension View {
  /// Streams the physical hinge angle into the model.
  ///
  /// The device hinge API (`onHingeChange`) ships in the iOS 27.1 SDK. Build with
  /// Xcode 27.1 and add `BASIS_DEVICE_HINGE` to the Swift active compilation
  /// conditions to enable it; until then the simulated hinge drives every lesson.
  func readsDeviceHinge(into model: HingeModel) -> some View {
    modifier(DeviceHingeReader(model: model))
  }
}

private struct DeviceHingeReader: ViewModifier {
  var model: HingeModel

  func body(content: Content) -> some View {
    #if BASIS_DEVICE_HINGE
    if #available(iOS 27.1, *) {
      content.onHingeChange(isEnabled: true) { _, context in
        guard let hinge = context.hinge else {
          model.useSimulatedHinge()
          return
        }
        // Calibration: verify on the Duo simulator that fully open reports 180°
        // and a right-angle pose reports 90°. If the API reports the fold angle
        // instead (0° flat), use `180 - hinge.angle.degrees` here.
        let status: HingeModel.Status = switch hinge.status {
        case .closed: .closed
        case .fullyOpen: .fullyOpen
        default: .partiallyOpen
        }
        model.receiveDeviceReading(openingDegrees: hinge.angle.degrees, status: status)
      }
    } else {
      content
    }
    #else
    content
    #endif
  }
}
