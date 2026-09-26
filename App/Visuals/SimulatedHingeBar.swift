import SwiftUI

/// Stand-in for the physical hinge on devices and SDKs without one.
struct SimulatedHingeBar: View {
  @Bindable var hinge: HingeModel

  var body: some View {
    VStack(spacing: 6) {
      Slider(value: $hinge.simulatedDegrees, in: 0...180) {
        Text("Simulated hinge angle")
      } minimumValueLabel: {
        Text("Closed")
      } maximumValueLabel: {
        Text("Flat")
      }
      .accessibilityValue(Text("\(Int(hinge.openingDegrees.rounded())) degrees"))
      Label("Simulated hinge. On iPhone Duo, the fold sets this angle.", systemImage: "angle")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .font(.footnote)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(.bar)
  }
}
