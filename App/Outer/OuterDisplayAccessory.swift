import SwiftUI

extension View {
  /// Attaches the outer display as a second render target (not a second navigation stack).
  ///
  /// iOS 27.0 provides `ExternalNonInteractiveAccessory`, which the system shows on another
  /// display when it chooses. iOS 27.1 adds `CameraCaptureAccessory`, which shows content on
  /// Duo's outer display while a camera session is active. Build with the 27.1 SDK and add
  /// `BASIS_CAMERA_ACCESSORY` to the Swift active compilation conditions to use it.
  func outerDisplayAccessory(_ state: OuterDisplayState) -> some View {
    modifier(OuterDisplayAccessory(state: state))
  }
}

private struct OuterDisplayAccessory: ViewModifier {
  var state: OuterDisplayState

  func body(content: Content) -> some View {
    #if BASIS_CAMERA_ACCESSORY
    if #available(iOS 27.1, *) {
      CameraAccessoryHost(state: state) { content }
    } else {
      content
    }
    #else
    if #available(iOS 27.0, *) {
      content
        .sceneAccessory {
          ExternalNonInteractiveAccessory {
            OuterSceneView(state: state)
          }
          .onAvailabilityChange { isAvailable in
            state.isAvailable = isAvailable
          }
        }
        .onAppear { state.path = .externalAccessory }
    } else {
      content
    }
    #endif
  }
}

#if BASIS_CAMERA_ACCESSORY
/// The pattern from the Duo Greetings sample: a live camera session keeps
/// `CameraCaptureAccessory` available on the outer display. The preview sits hidden
/// behind the blackboard; no camera feed is part of the lesson UI.
@available(iOS 27.1, *)
private struct CameraAccessoryHost<Content: View>: View {
  var state: OuterDisplayState
  @ViewBuilder var content: Content

  @Environment(\.scenePhase) private var scenePhase
  @State private var camera = CameraSessionModel()

  var body: some View {
    ZStack {
      CameraPreview(session: camera.session)
        .ignoresSafeArea()
        .accessibilityHidden(true)
      content
    }
    .sceneAccessory {
      CameraCaptureAccessory {
        OuterSceneView(state: state)
      }
      .onAvailabilityChange { isAvailable in
        state.isAvailable = isAvailable
      }
    }
    .onAppear { state.path = .cameraAccessory }
    .task(id: scenePhase) {
      if scenePhase == .active {
        await camera.start()
      } else {
        camera.stop()
      }
    }
    .onDisappear { camera.stop() }
  }
}
#endif
