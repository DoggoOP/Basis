import SwiftUI

extension EnvironmentValues {
  /// When true, formulas and labels are shown; the default demo view emphasizes geometry.
  @Entry var explainsMath = false
}

/// An equation that fades in only once the geometry has motivated it.
struct Equation: View {
  var text: String
  /// Extra condition beyond Explain mode that also reveals the equation.
  var revealed = false
  var tint: Color = Theme.neutral

  @Environment(\.explainsMath) private var explainsMath

  init(_ text: String, revealed: Bool = false, tint: Color = Theme.neutral) {
    self.text = text
    self.revealed = revealed
    self.tint = tint
  }

  var body: some View {
    let isVisible = explainsMath || revealed
    Text(text)
      .font(.system(.title3, design: .serif).italic())
      .foregroundStyle(tint)
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 6)
      .animation(Motion.reveal, value: isVisible)
      .accessibilityHidden(!isVisible)
  }
}

/// A bracketed matrix of formatted numbers.
struct MatrixText: View {
  var name: String?
  var rows: [[Double]]
  var fractionDigits = 2
  var tint: Color = Theme.neutral

  var body: some View {
    HStack(spacing: 10) {
      if let name {
        Text("\(name) =")
          .font(.system(.title3, design: .serif).italic())
      }
      HStack(spacing: 0) {
        bracket(isLeading: true)
        Grid(horizontalSpacing: 14, verticalSpacing: 4) {
          ForEach(rows.indices, id: \.self) { r in
            GridRow {
              ForEach(rows[r].indices, id: \.self) { c in
                Text(rows[r][c].cleaned(fractionDigits: fractionDigits), format: .number.precision(.fractionLength(fractionDigits)))
                  .monospacedDigit()
                  .gridColumnAlignment(.trailing)
              }
            }
          }
        }
        .padding(.horizontal, 6)
        bracket(isLeading: false)
      }
      .font(.system(.body, design: .rounded).weight(.medium))
    }
    .foregroundStyle(tint)
    .fixedSize()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityDescription)
  }

  private func bracket(isLeading: Bool) -> some View {
    BracketShape(isLeading: isLeading)
      .stroke(tint.opacity(0.8), lineWidth: 1.5)
      .frame(width: 6)
  }

  private var accessibilityDescription: String {
    let body = rows.map { $0.map { $0.cleaned(fractionDigits: fractionDigits).formatted() }.joined(separator: ", ") }
      .joined(separator: "; ")
    return "\(name ?? "Matrix"): \(body)"
  }
}

private struct BracketShape: Shape {
  var isLeading: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let outer = isLeading ? rect.maxX : rect.minX
    let inner = isLeading ? rect.minX : rect.maxX
    path.move(to: CGPoint(x: outer, y: rect.minY))
    path.addLine(to: CGPoint(x: inner, y: rect.minY))
    path.addLine(to: CGPoint(x: inner, y: rect.maxY))
    path.addLine(to: CGPoint(x: outer, y: rect.maxY))
    return path
  }
}
