import SwiftUI

/// Special mathematical states deserve a full-screen moment.
enum SpecialMoment: Equatable {
  case orthogonal
  case dimensionLost
  case fiftyFifty

  var title: String {
    switch self {
    case .orthogonal: "Orthogonal"
    case .dimensionLost: "One Dimension Lost"
    case .fiftyFifty: "50 / 50"
    }
  }

  var subtitle: String {
    switch self {
    case .orthogonal: "a · b = 0"
    case .dimensionLost: "These directions no longer span the space."
    case .fiftyFifty: "Perpendicular Bloch axes"
    }
  }

  var tint: Color {
    switch self {
    case .orthogonal: Theme.hinge
    case .dimensionLost: Theme.warning
    case .fiftyFifty: Theme.dual
    }
  }

  /// The moment a basis is in, if any.
  static func forBasis(_ basis: BasisGeometry) -> SpecialMoment? {
    if basis.isSingular { return .dimensionLost }
    if basis.isOrthogonal { return .orthogonal }
    return nil
  }
}

extension View {
  /// Briefly fills the screen with a state's name when the geometry reaches it.
  func specialMoment(_ moment: SpecialMoment?) -> some View {
    modifier(SpecialMomentOverlay(moment: moment))
  }
}

private struct SpecialMomentOverlay: ViewModifier {
  var moment: SpecialMoment?

  @State private var shown: SpecialMoment?

  func body(content: Content) -> some View {
    content
      .overlay {
        if let shown {
          VStack(spacing: 10) {
            Text(shown.title)
              .font(.system(size: 64, weight: .bold, design: .rounded))
              .textCase(.uppercase)
              .minimumScaleFactor(0.4)
              .lineLimit(1)
              .foregroundStyle(shown.tint)
            Text(shown.subtitle)
              .font(.system(.title2, design: .serif).italic())
              .foregroundStyle(Theme.neutral)
          }
          .padding(.horizontal, 40)
          .padding(.vertical, 28)
          .background(Theme.background.opacity(0.82), in: .rect(cornerRadius: 32))
          .transition(.opacity.combined(with: .scale(scale: 0.96)))
          .allowsHitTesting(false)
          .accessibilityAddTraits(.updatesFrequently)
        }
      }
      .task(id: moment) {
        guard let moment else {
          withAnimation(Motion.reveal) { shown = nil }
          return
        }
        withAnimation(Motion.reveal) { shown = moment }
        try? await Task.sleep(for: .seconds(1.4))
        withAnimation(Motion.reveal) { shown = nil }
      }
  }
}
