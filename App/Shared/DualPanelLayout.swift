import SwiftUI

/// Places one lesson surface on each side of the hinge, with a narrow spine on the hinge itself.
///
/// Near-square spaces (the unfolded inner display) fold along their long axis, so the
/// panels sit side by side in portrait and stacked in landscape. Elongated spaces
/// (conventional iPhones) split their long dimension instead.
struct DualPanelLayout<Leading: View, Spine: View, Trailing: View>: View {
  static var spineThickness: CGFloat { 44 }

  @ViewBuilder var leading: Leading
  @ViewBuilder var spine: Spine
  @ViewBuilder var trailing: Trailing

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      if Self.hingeIsVertical(for: size) {
        HStack(spacing: 0) {
          panel(leading, edge: .trailing)
          spineContainer(edge: .trailing)
            .frame(width: Self.spineThickness)
          panel(trailing, edge: .leading)
        }
      } else {
        VStack(spacing: 0) {
          panel(leading, edge: .bottom)
          spineContainer(edge: .bottom)
            .frame(height: Self.spineThickness)
          panel(trailing, edge: .top)
        }
      }
    }
    .background(MathPalette.panelBackground)
  }

  static func hingeIsVertical(for size: CGSize) -> Bool {
    let aspect = max(size.width, size.height) / max(min(size.width, size.height), 1)
    let isNearSquare = aspect < 1.45
    return isNearSquare ? size.height >= size.width : size.width > size.height
  }

  private func panel(_ content: some View, edge: HingeEdge) -> some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .environment(\.hingeEdge, edge)
      .clipped()
  }

  private func spineContainer(edge: HingeEdge) -> some View {
    spine
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(MathPalette.spineBackground)
      .environment(\.hingeEdge, edge)
  }
}
