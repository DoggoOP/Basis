import SwiftUI

extension View {
  /// Attaches the outer display as a second render target (not a second navigation stack).
  ///
  /// On iOS 27.1+, `CameraCaptureAccessory` shows content on Duo's outer display while a
  /// camera session is active: the pattern from the Duo Greetings sample. On iOS 27.0,
  /// `ExternalNonInteractiveAccessory` lets the system place it on another display.
  func outerDisplayAccessory(_ state: OuterDisplayState, hinge: HingeModel) -> some View {
    modifier(OuterDisplayAccessory(state: state, hinge: hinge))
  }
}

private struct OuterDisplayAccessory: ViewModifier {
  var state: OuterDisplayState
  var hinge: HingeModel

  func body(content: Content) -> some View {
    if #available(iOS 27.1, *) {
      CameraAccessoryHost(state: state, hinge: hinge) { content }
    } else if #available(iOS 27.0, *) {
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
  }
}

/// A live front-camera session keeps `CameraCaptureAccessory` available on the outer display.
/// The preview sits hidden behind the blackboard; no camera feed is part of the lesson UI.
/// The session pauses whenever it isn't needed, including while this iPhone is the probe
/// (ARKit needs the camera there).
@available(iOS 27.1, *)
private struct CameraAccessoryHost<Content: View>: View {
  var state: OuterDisplayState
  var hinge: HingeModel
  @ViewBuilder var content: Content

  @Environment(\.scenePhase) private var scenePhase
  @State private var camera = CameraSessionModel()

  private var wantsCamera: Bool {
    // Only a device that reports a hinge (iPhone Duo) has an outer display to keep alive.
    scenePhase == .active && hinge.isDeviceHingeAvailable && state.mode == .automatic && !state.isCameraSuspended
  }

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
    .task(id: wantsCamera) {
      if wantsCamera {
        await camera.start()
      } else {
        camera.stop()
      }
    }
    .onDisappear { camera.stop() }
  }
}
