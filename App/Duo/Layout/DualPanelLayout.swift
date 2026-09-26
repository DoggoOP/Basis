import SwiftUI

/// Places one lesson surface on each side of the hinge, with a narrow spine on the hinge itself.
///
/// On iPhone Duo (iOS 27.1+) the split follows the fold's division reserved region: its
/// position, orientation, and width. The region is queried even while inactive, so the
/// hinge orientation stays right when the device is flat. Elsewhere, near-square spaces
/// fold along their long axis and elongated spaces split their long dimension.
struct DualPanelLayout<Leading: View, Spine: View, Trailing: View>: View {
  static var spineThickness: CGFloat { 44 }

  @ViewBuilder var leading: Leading
  @ViewBuilder var spine: Spine
  @ViewBuilder var trailing: Trailing

  var body: some View {
    GeometryReader { proxy in
      let split = Self.split(in: proxy)
      if split.isVertical {
        HStack(spacing: 0) {
          panel(leading, edge: .trailing)
            .frame(width: max(split.position - split.thickness / 2, 0))
          spineContainer(edge: .trailing)
            .frame(width: split.thickness)
          panel(trailing, edge: .leading)
        }
      } else {
        VStack(spacing: 0) {
          panel(leading, edge: .bottom)
            .frame(height: max(split.position - split.thickness / 2, 0))
          spineContainer(edge: .bottom)
            .frame(height: split.thickness)
          panel(trailing, edge: .top)
        }
      }
    }
    .background(Theme.background)
  }

  /// Where the hinge is, in this view's coordinates.
  struct Split {
    var isVertical: Bool
    /// Center of the hinge along the split axis.
    var position: CGFloat
    var thickness: CGFloat
  }

  static func split(in proxy: GeometryProxy) -> Split {
    let size = proxy.size
    #if canImport(SwiftUI, _version: 8.1)
    if #available(iOS 27.1, *),
       let fold = proxy.reservedRegions(kind: .division, options: .includeInactive).first {
      let frame = fold.frame
      let isVertical = frame.height >= frame.width
      let foldWidth = isVertical
        ? frame.width + fold.margins.leading + fold.margins.trailing
        : frame.height + fold.margins.top + fold.margins.bottom
      return Split(
        isVertical: isVertical,
        position: isVertical ? frame.midX : frame.midY,
        thickness: max(fold.isActive ? foldWidth : 0, spineThickness)
      )
    }
    #endif
    let isVertical = hingeIsVertical(for: size)
    return Split(isVertical: isVertical, position: (isVertical ? size.width : size.height) / 2, thickness: spineThickness)
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
      .background(Theme.spine)
      .environment(\.hingeEdge, edge)
  }
}
