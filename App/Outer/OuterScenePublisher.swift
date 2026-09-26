import SwiftUI

extension View {
  /// Projects a lesson's consequence onto the outer display while the lesson is visible.
  func publishesOuterScene(_ scene: OuterScene) -> some View {
    modifier(OuterScenePublisher(scene: scene))
  }
}

private struct OuterScenePublisher: ViewModifier {
  var scene: OuterScene

  @Environment(OuterDisplayState.self) private var outer

  func body(content: Content) -> some View {
    let coordinator = OuterDisplayCoordinator(state: outer)
    content
      .onChange(of: scene, initial: true) { _, newValue in coordinator.present(newValue) }
      .onDisappear { coordinator.dismiss() }
  }
}
