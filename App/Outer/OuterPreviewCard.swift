import SwiftUI

/// Developer-only: a small live copy of the outer display, shown on the inner display.
/// Hide it for judging (Hinge Calibration → Outer Display).
struct OuterPreviewCard: View {
  var state: OuterDisplayState

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Label(state.usesOuterDisplay ? "Outer preview · live" : "Outer preview · inner fallback", systemImage: "rectangle.on.rectangle.angled")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      OuterSceneView(state: state)
        .frame(width: 280, height: 190)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15)))
        .allowsHitTesting(false)
    }
    .padding(8)
    .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Outer display preview")
  }
}
