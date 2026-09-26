import SwiftUI

/// Launches directly into the demo experience; Explore Mode is reachable from its toolbar.
struct RootView: View {
  @State private var path: [Route] = []

  var body: some View {
    NavigationStack(path: $path) {
      DemoView()
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .explore: ExploreHomeView()
          case .lab(let lab): LabContainerView(lab: lab)
          case .probe: ProbeView()
          case .calibration: CalibrationView()
          }
        }
    }
    .tint(Theme.hinge)
  }
}
