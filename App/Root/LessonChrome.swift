import SwiftUI

extension View {
  /// Shared lesson surroundings: blackboard background, the simulated hinge stand-in,
  /// special-angle haptics, and the Explain environment.
  func lessonChrome(usesHinge: Bool, explains: Bool) -> some View {
    modifier(LessonChrome(usesHinge: usesHinge, explains: explains))
  }
}

private struct LessonChrome: ViewModifier {
  var usesHinge: Bool
  var explains: Bool

  @Environment(HingeModel.self) private var hinge
  @Environment(OuterDisplayState.self) private var outer

  func body(content: Content) -> some View {
    content
      .environment(\.explainsMath, explains)
      .overlay(alignment: .topTrailing) {
        if outer.showsPreview {
          OuterPreviewCard(state: outer)
            .padding(12)
        }
      }
      .background(Theme.background.ignoresSafeArea())
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if usesHinge && hinge.source == .simulated {
          SimulatedHingeBar(hinge: hinge)
        }
      }
      .sensoryFeedback(trigger: usesHinge ? hinge.landmark : nil) { _, new in
        switch new {
        case .orthogonal: .impact(weight: .medium, intensity: 1)
        case .some: .impact(weight: .light, intensity: 0.5)
        case nil: nil
        }
      }
      .navigationBarTitleDisplayMode(.inline)
  }
}

/// Toolbar toggle that reveals formulas and labels.
struct ExplainToggle: View {
  @Binding var isOn: Bool

  var body: some View {
    Toggle("Explain", systemImage: "function", isOn: $isOn)
      .toggleStyle(.button)
  }
}
