import SwiftUI

struct RootView: View {
  @State private var path: [Route] = []

  var body: some View {
    NavigationStack(path: $path) {
      ExploreHomeView()
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .demo: DemoView()
          case .lab(let lab): LabContainerView(lab: lab)
          case .probe: ProbeView()
          case .calibration: CalibrationView()
          }
        }
    }
    .tint(Theme.hinge)
  }
}
