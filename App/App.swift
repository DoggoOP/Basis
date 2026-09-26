import SwiftUI

@main
struct BasisApp: App {
  @State private var hinge = HingeModel()
  @State private var probeLink = HostPeerService()
  @State private var outer = OuterDisplayState()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(hinge)
        .environment(probeLink)
        .environment(outer)
        .readsDeviceHinge(into: hinge)
        .outerDisplayAccessory(outer)
        .preferredColorScheme(.dark)
    }
  }
}
