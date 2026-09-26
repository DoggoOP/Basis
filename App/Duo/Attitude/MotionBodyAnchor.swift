import SwiftUI
import UIKit

extension View {
  /// Makes the panel this view sits on the body that device motion is measured for.
  func definesMotionBody(for attitude: DuoAttitudeProvider) -> some View {
    background(MotionBodyAnchor(attitude: attitude).allowsHitTesting(false).accessibilityHidden(true))
  }
}

/// An invisible UIKit view handed to CoreMotion as `deviceMotionBody` once it's in a window.
private struct MotionBodyAnchor: UIViewRepresentable {
  var attitude: DuoAttitudeProvider

  func makeUIView(context: Context) -> AnchorView {
    let view = AnchorView()
    view.onWindowChange = { [weak view] hasWindow in
      attitude.setBody(hasWindow ? view : nil)
    }
    return view
  }

  func updateUIView(_ view: AnchorView, context: Context) {}

  final class AnchorView: UIView {
    var onWindowChange: ((Bool) -> Void)?

    override func didMoveToWindow() {
      super.didMoveToWindow()
      onWindowChange?(window != nil)
    }
  }
}
