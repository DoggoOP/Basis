import SwiftUI

extension View {
  /// Streams the physical hinge angle into the model (iOS 27.1+ on devices with a hinge).
  /// Elsewhere, the simulated hinge drives every lesson.
  func readsDeviceHinge(into model: HingeModel) -> some View {
    modifier(DeviceHingeReader(model: model))
  }
}

private struct DeviceHingeReader: ViewModifier {
  var model: HingeModel

  func body(content: Content) -> some View {
    // The hinge API ships in the iOS 27.1 SDK (SwiftUI 8.1); older SDKs use the simulated hinge.
    #if canImport(SwiftUI, _version: 8.1)
    if #available(iOS 27.1, *) {
      content.onHingeChange { _, context in
        guard let hinge = context.hinge else {
          model.useSimulatedHinge()
          return
        }
        let status: HingeModel.Status = switch hinge.status {
        case .closed: .closed
        case .fullyOpen: .fullyOpen
        default: .partiallyOpen
        }
        let raw = hinge.angle.degrees
        model.receiveDeviceReading(
          openingDegrees: HingeCalibration.openingDegrees(fromRaw: raw),
          rawDegrees: raw,
          status: status
        )
      }
    } else {
      content
    }
    #else
    content
    #endif
  }
}
