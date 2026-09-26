import SwiftUI

/// Small uppercase caption naming what a panel represents.
struct PanelTitle: View {
  var title: String
  var tint: Color = .secondary

  init(_ title: String, tint: Color = .secondary) {
    self.title = title
    self.tint = tint
  }

  var body: some View {
    Text(title)
      .font(.caption.weight(.bold))
      .tracking(1.4)
      .textCase(.uppercase)
      .foregroundStyle(tint)
      .accessibilityAddTraits(.isHeader)
  }
}

/// A labeled value row, e.g. "σ₁   1.31".
struct ValueRow: View {
  var label: String
  var value: String
  var tint: Color = Theme.neutral

  var body: some View {
    HStack(spacing: 16) {
      Text(label)
        .font(.system(.body, design: .serif).italic())
        .foregroundStyle(tint)
        .frame(minWidth: 28, alignment: .leading)
      Text(value)
        .font(.system(.title3, design: .rounded).weight(.semibold))
        .monospacedDigit()
        .contentTransition(.numericText())
    }
    .accessibilityElement(children: .combine)
  }
}

/// A panel's content column, aligned to the side away from the hinge.
struct PanelStack<Content: View>: View {
  var spacing: CGFloat = 16
  @ViewBuilder var content: Content

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    VStack(alignment: edge.horizontalAlignment, spacing: spacing) {
      content
    }
    .panelContent()
  }
}

/// A vertical stack aligned to the side away from the hinge, without panel margins.
struct AlignedStack<Content: View>: View {
  var spacing: CGFloat = 8
  @ViewBuilder var content: Content

  @Environment(\.hingeEdge) private var edge

  var body: some View {
    VStack(alignment: edge.horizontalAlignment, spacing: spacing) {
      content
    }
  }
}
