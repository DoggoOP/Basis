import SwiftUI

/// A small caps caption over a large, steady number.
struct Readout<Value: View>: View {
  var title: String
  var tint: Color = .secondary
  @ViewBuilder var value: Value

  @Environment(\.hingeEdge) private var hingeEdge

  var body: some View {
    VStack(alignment: hingeEdge.horizontalAlignment, spacing: 2) {
      Text(title)
        .font(.caption.weight(.semibold))
        .tracking(1.2)
        .textCase(.uppercase)
        .foregroundStyle(tint)
      value
        .font(.system(size: 44, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .contentTransition(.numericText())
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
    .accessibilityElement(children: .combine)
  }
}

/// A capsule badge announcing a special mathematical state.
struct StateBadge: View {
  var title: String
  var tint: Color

  var body: some View {
    Text(title)
      .font(.subheadline.weight(.bold))
      .tracking(1)
      .textCase(.uppercase)
      .foregroundStyle(tint)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(tint.opacity(0.16), in: .capsule)
  }
}

extension View {
  /// Lays out panel content in the corner away from the hinge, with standard margins.
  func panelContent() -> some View {
    modifier(PanelContentLayout())
  }
}

private struct PanelContentLayout: ViewModifier {
  @Environment(\.hingeEdge) private var hingeEdge

  func body(content: Content) -> some View {
    content
      .multilineTextAlignment(hingeEdge.textAlignment)
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hingeEdge.outerAlignment)
  }
}
