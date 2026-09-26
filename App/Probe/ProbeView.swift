import SwiftUI

/// The companion instrument on an ordinary iPhone: it is the endpoint of a vector p.
struct ProbeView: View {
  @State private var tracking = ProbeTrackingModel()
  @State private var peers = ProbePeerService()

  var body: some View {
    VStack(spacing: 28) {
      VStack(spacing: 8) {
        Text("Basis Probe")
          .font(.title.weight(.bold))
          .textCase(.uppercase)
          .tracking(2)
        Label(peers.connectedHost.map { "Connected to \($0)" } ?? "Waiting for Duo…", systemImage: "dot.radiowaves.left.and.right")
          .font(.headline)
          .foregroundStyle(peers.connectedHost == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(Theme.hinge))
      }

      if tracking.tracking == .unsupported {
        ContentUnavailableView(
          "Tracking Unavailable",
          systemImage: "move.3d",
          description: Text("Run the probe on a physical iPhone. The simulator can't track motion in space.")
        )
      } else {
        VStack(alignment: .leading, spacing: 10) {
          Text("p")
            .font(.system(size: 44, weight: .semibold, design: .serif).italic())
            .foregroundStyle(Theme.probe)
          ForEach(Array(zip(["x", "y", "z"], components)), id: \.0) { axis, value in
            HStack(spacing: 20) {
              Text(axis)
                .font(.system(.title, design: .serif).italic())
                .foregroundStyle(.secondary)
                .frame(width: 30)
              Text(value.map { $0.signedText() + " m" } ?? "—")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)
          }
        }
        StateBadge(title: trackingTitle, tint: tracking.tracking == .good ? Theme.hinge : Theme.first)
        Text("Hold the phone upright, facing you, then tap Recenter. The rear camera must stay uncovered.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button("Recenter", systemImage: "scope") { tracking.recenter() }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background.ignoresSafeArea())
    .navigationTitle("Probe")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      tracking.onUpdate = { [peers] packet in peers.send(packet) }
      tracking.start()
      peers.start()
      UIApplication.shared.isIdleTimerDisabled = true
    }
    .onDisappear {
      tracking.stop()
      peers.stop()
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }

  private var components: [Double?] {
    guard let p = tracking.position else { return [nil, nil, nil] }
    return [p.x, p.y, p.z]
  }

  private var trackingTitle: String {
    switch tracking.tracking {
    case .starting: "Starting…"
    case .good: "Tracking good"
    case .moveSlowly: "Move phone slowly"
    case .unsupported: "Unavailable"
    }
  }
}
