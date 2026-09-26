import SwiftUI

/// Shows exactly what whole-device attitude this device (or simulator) exposes to the app,
/// so the frame-rotation act is only described as sensed when it really is.
struct AttitudeDiagnosticsSection: View {
  @Environment(DuoAttitudeProvider.self) private var attitude
  @State private var interfaceOrientation = "—"

  var body: some View {
    Section {
      LabeledContent("Device motion", value: attitude.isDeviceMotionAvailable ? "Available" : "Not available")
      LabeledContent("Authorization", value: attitude.authorizationDescription)
      LabeledContent("Motion body", value: attitude.usesPanelBody ? "This panel (deviceMotionBody)" : "Whole device")
      LabeledContent("Source", value: sourceText)
      LabeledContent("Samples", value: attitude.sampleCount.formatted())
      LabeledContent("Frame yaw", value: attitude.yawDegrees.degreesText())
      if let ypr = attitude.rawYawPitchRoll {
        LabeledContent("Yaw · pitch · roll", value: "\(ypr.x.degreesText(fractionDigits: 0)) · \(ypr.y.degreesText(fractionDigits: 0)) · \(ypr.z.degreesText(fractionDigits: 0))")
      }
      if let q = attitude.rawQuaternion {
        LabeledContent("Quaternion", value: "\(q.real.fixedText()) \(q.imag.x.signedText()) \(q.imag.y.signedText()) \(q.imag.z.signedText())")
          .monospacedDigit()
      }
      LabeledContent("Interface orientation", value: interfaceOrientation)
      HStack {
        Button(attitude.isRunning ? "Stop" : "Start") {
          attitude.isRunning ? attitude.stop() : attitude.start()
        }
        Spacer()
        Button("Set Reference") { attitude.resetReference() }
      }
      .buttonStyle(.bordered)
    } header: {
      Text("Attitude")
    } footer: {
      Text("Turn the device (or use the simulator's rotate control) and watch Samples and Frame yaw. If no samples arrive, Hold the Point uses a labeled demo control and never claims the rotation is sensed.")
    }
    .definesMotionBody(for: attitude)
    .onAppear { attitude.start() }
    .onGeometryChange(for: String.self) { _ in currentInterfaceOrientation() } action: { interfaceOrientation = $0 }
  }

  private var sourceText: String {
    switch attitude.source {
    case .waitingForSensor: "Waiting for samples…"
    case .continuousSensor: "Sensed (CoreMotion)"
    case .simulatedControl: "Demo control (not sensed)"
    }
  }

  private func currentInterfaceOrientation() -> String {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    switch scene?.effectiveGeometry.interfaceOrientation {
    case .portrait: return "Portrait"
    case .portraitUpsideDown: return "Portrait upside down"
    case .landscapeLeft: return "Landscape left"
    case .landscapeRight: return "Landscape right"
    default: return "Unknown"
    }
  }
}
