import SwiftUI

/// Verifies the device hinge's angle convention before trusting any lesson math.
struct CalibrationView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer
  @State private var recorded: [Pose: Double] = [:]

  enum Pose: String, CaseIterable, Identifiable {
    case fullyOpen = "Fully open"
    case rightAngle = "Right angle"
    case nearlyClosed = "Nearly closed"

    var id: Self { self }

    var expected: Double {
      switch self {
      case .fullyOpen: 180
      case .rightAngle: 90
      case .nearlyClosed: 10
      }
    }
  }

  var body: some View {
    @Bindable var outer = outer
    Form {
      Section {
        LabeledContent("Path", value: outer.path.rawValue)
        LabeledContent("Available", value: outer.isAvailable ? "Yes" : "No")
        LabeledContent("Presenting", value: outer.isPresented ? "Yes" : "No, inner fallback")
        Picker("Mode", selection: $outer.mode) {
          ForEach(OuterDisplayState.Mode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        Toggle("Outer Preview", isOn: $outer.showsPreview)
      } header: {
        Text("Outer Display")
      } footer: {
        Text("Inside is the construction; outside is the consequence. If the outer display is unreliable, choose Inner Only and every lesson uses its two-panel fallback. Turn Outer Preview off before judging.")
      }
      AttitudeDiagnosticsSection()
      Section("Hinge") {
        LabeledContent("Source", value: hinge.source == .device ? "Device hinge" : "Simulated hinge")
        LabeledContent("Status", value: statusText)
        LabeledContent("Raw API angle", value: hinge.rawDeviceDegrees?.degreesText() ?? "—")
        LabeledContent("Opening angle α", value: hinge.openingDegrees.degreesText())
      }
      Section {
        ForEach(Pose.allCases) { pose in
          HStack {
            VStack(alignment: .leading) {
              Text(pose.rawValue)
              Text("Expect α ≈ \(pose.expected.degreesText(fractionDigits: 0))")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let value = recorded[pose] {
              Text(value.degreesText())
                .monospacedDigit()
                .foregroundStyle(abs(value - pose.expected) < 12 ? Theme.hinge : Theme.warning)
            }
            Button("Record") { recorded[pose] = hinge.rawDeviceDegrees ?? hinge.openingDegrees }
              .buttonStyle(.bordered)
          }
        }
      } header: {
        Text("Checklist")
      } footer: {
        Text(conventionAdvice)
      }
    }
    .scrollContentBackground(.hidden)
    .background(Theme.background.ignoresSafeArea())
    .navigationTitle("Calibration")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var statusText: String {
    switch hinge.status {
    case .closed: "Closed"
    case .partiallyOpen: "Partially open"
    case .fullyOpen: "Fully open"
    }
  }

  private var conventionAdvice: String {
    guard let open = recorded[.fullyOpen], let closed = recorded[.nearlyClosed] else {
      return "Fold the device into each pose and tap Record. Every lesson depends on α, the physical opening angle."
    }
    return open > closed
      ? "Raw angle increases as the device opens: the opening-angle convention is correct."
      : "Raw angle decreases as the device opens: set HingeCalibration.convention to .foldAngle."
  }
}
