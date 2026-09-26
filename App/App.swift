import SwiftUI

@main
struct BasisApp: App {
  @State private var hinge = HingeModel()
  @State private var probeLink = HostPeerService()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(hinge)
        .environment(probeLink)
        .readsDeviceHinge(into: hinge)
        .preferredColorScheme(.dark)
    }
  }
}
