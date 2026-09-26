import SwiftUI

@main
struct BasisApp: App {
  @State private var hinge = HingeModel()
  @State private var probeLink = HostPeerService()
  @State private var outer = OuterDisplayState()
  @State private var attitude = DuoAttitudeProvider()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(hinge)
        .environment(probeLink)
        .environment(outer)
        .environment(attitude)
        .readsDeviceHinge(into: hinge)
        .outerDisplayAccessory(outer, hinge: hinge)
        .preferredColorScheme(.dark)
    }
  }
}
