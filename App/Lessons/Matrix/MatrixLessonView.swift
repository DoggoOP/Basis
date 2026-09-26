import SwiftUI

enum MatrixStage {
  /// Each panel shows one basis direction starting at the hinge.
  case directions
  /// Coefficient space on one panel, physical space on the other: p = B c.
  case transform
}

/// Act I: the phone is a matrix.
struct MatrixLessonView: View {
  @Binding var stage: MatrixStage

  var body: some View {
    Group {
      switch stage {
      case .directions:
        PhysicalDirectionsView {
          withAnimation(Motion.morph) { stage = .transform }
        }
      case .transform:
        UnitCircleTransformView()
      }
    }
    .transition(.opacity)
  }
}
