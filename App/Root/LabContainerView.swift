import SwiftUI

/// Hosts a single Explore Mode lab.
struct LabContainerView: View {
  var lab: Lab

  @State private var explains = false

  var body: some View {
    LabContent(lab: lab)
      .lessonChrome(usesHinge: lab.usesHinge, explains: explains)
      .navigationTitle(lab.title)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          ExplainToggle(isOn: $explains)
        }
      }
  }
}

/// Resolves a lab to its lesson view.
struct LabContent: View {
  var lab: Lab

  var body: some View {
    switch lab {
    case .directions: DirectionsLessonView()
    case .physicalPoint: PhysicalPointLessonView()
    case .conditioning: ConditioningLessonView()
    case .duality: DualityLessonView()
    case .qubit: QuantumLessonView()
    case .maps: LinearMapLessonView()
    case .orthogonalize: GramSchmidtLessonView()
    case .reflections: ReflectionLessonView()
    case .flux: OrientationLessonView()
    case .surface: IntrinsicExtrinsicView()
    }
  }
}
