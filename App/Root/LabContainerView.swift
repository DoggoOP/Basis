import SwiftUI

/// Hosts a single Explore Mode lab.
struct LabContainerView: View {
  var lab: Lab

  @State private var explains = false
  @State private var matrixStage = MatrixStage.directions

  var body: some View {
    LabContent(lab: lab, matrixStage: $matrixStage)
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
  @Binding var matrixStage: MatrixStage

  var body: some View {
    switch lab {
    case .matrix: MatrixLessonView(stage: $matrixStage)
    case .coordinates: ChangeOfBasisView()
    case .duality: DualityLessonView()
    case .maps: LinearMapLessonView()
    case .orthogonalize: GramSchmidtLessonView()
    case .reflections: ReflectionLessonView()
    case .qubit: QuantumLessonView()
    case .orientation: OrientationLessonView()
    case .surface: IntrinsicExtrinsicView()
    }
  }
}
