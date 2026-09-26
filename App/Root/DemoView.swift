import SwiftUI

/// The judged demo. The app launches straight here; Explore is one tap away.
struct DemoView: View {
  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer
  @State private var coordinator = DemoCoordinator()
  @State private var explains = false

  var body: some View {
    LabContent(lab: coordinator.act.lab)
      .id("\(coordinator.act.rawValue)-\(coordinator.resetCount)")
      .transition(.opacity)
      .animation(Motion.reveal, value: coordinator.act)
      .lessonChrome(usesHinge: coordinator.act.lab.usesHinge, explains: explains)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          NavigationLink(value: Route.explore) {
            Label("Explore", systemImage: "square.grid.2x2")
          }
        }
        ToolbarItem(placement: .principal) {
          VStack(spacing: 0) {
            Text("Act \(coordinator.act.rawValue) / \(DemoAct.allCases.count)" + (outer.usesOuterDisplay ? " · \(coordinator.act.outerTitle)" : ""))
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
            Text(coordinator.act.title)
              .font(.headline)
          }
          .accessibilityElement(children: .combine)
        }
        ToolbarItemGroup(placement: .primaryAction) {
          Button("Previous", systemImage: "chevron.backward") {
            coordinator.previous(hinge: hinge)
          }
          .disabled(coordinator.isFirstAct)
          Button("Reset Act", systemImage: "arrow.counterclockwise") {
            coordinator.resetAct(hinge: hinge)
          }
          ExplainToggle(isOn: $explains)
          Button("Next", systemImage: "chevron.forward") {
            coordinator.next(hinge: hinge)
          }
          .disabled(coordinator.isLastAct)
        }
      }
      .onAppear { hinge.setSimulatedPose(coordinator.act.startingPose) }
  }
}
