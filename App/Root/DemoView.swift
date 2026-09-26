import SwiftUI

/// The judged demo: five acts, one Next button, each act starting from a preset.
struct DemoView: View {
  @Environment(HingeModel.self) private var hinge
  @State private var coordinator = DemoCoordinator()
  @State private var explains = false

  var body: some View {
    LabContent(lab: coordinator.act.lab, matrixStage: matrixStage)
      .id("\(coordinator.act.rawValue)-\(coordinator.resetCount)")
      .transition(.opacity)
      .animation(Motion.reveal, value: coordinator.step)
      .lessonChrome(usesHinge: coordinator.act.lab.usesHinge, explains: explains)
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack(spacing: 0) {
            Text("Act \(coordinator.act.rawValue) / \(DemoAct.allCases.count)")
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
          .disabled(coordinator.isFirstStep)
          Button("Reset Act", systemImage: "arrow.counterclockwise") {
            coordinator.resetAct(hinge: hinge)
          }
          ExplainToggle(isOn: $explains)
          Button("Next", systemImage: "chevron.forward") {
            coordinator.next(hinge: hinge)
          }
          .disabled(coordinator.isLastStep)
        }
      }
      .onAppear { coordinator.start(hinge: hinge) }
  }

  /// The demo drives the Matrix act's stage; taps inside the lesson can still advance it.
  private var matrixStage: Binding<MatrixStage> {
    Binding {
      coordinator.matrixStage
    } set: { newValue in
      if newValue == .transform, coordinator.step == .phoneIsMatrix {
        coordinator.next(hinge: hinge)
      }
    }
  }
}
