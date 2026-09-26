import SwiftUI

/// Act IV: two display regions become two vector spaces, related by A.
struct LinearMapLessonView: View {
  @State private var preset = LinearMapPreset.rotate
  /// The matrix being drawn; animates between presets so shapes morph rather than swap.
  @State private var matrix = LinearMapPreset.rotate.matrix
  @State private var x = SIMD2(0.7, 0.45)
  /// Properties are labeled only after the geometry has finished morphing.
  @State private var labeledPreset: LinearMapPreset?

  var body: some View {
    DualPanelLayout {
      PanelStack(spacing: 14) {
        PanelTitle("Domain V", tint: Theme.first)
        DomainView(matrix: matrix, x: $x, showsKernel: labeledPreset == preset)
        Picker("Map", selection: $preset) {
          ForEach(LinearMapPreset.allCases) { preset in
            Text(preset.title).tag(preset)
          }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
      }
    } spine: {
      MapArrowSpine(label: "A")
    } trailing: {
      PanelStack(spacing: 14) {
        PanelTitle("Codomain W", tint: Theme.second)
        CodomainView(matrix: matrix, x: x, showsImage: labeledPreset == preset)
        MapPropertiesView(matrix: preset.matrix, isRevealed: labeledPreset == preset)
      }
    }
    .onChange(of: preset) { _, newValue in
      withAnimation(Motion.morph) { matrix = newValue.matrix }
    }
    .task(id: preset) {
      labeledPreset = nil
      try? await Task.sleep(for: .seconds(0.9))
      withAnimation(Motion.reveal) { labeledPreset = preset }
    }
    .sensoryFeedback(.selection, trigger: preset)
  }
}

/// Grid, unit circle, the draggable vector x, and (for rank-deficient maps) the kernel.
private struct DomainView: View, Animatable {
  var matrix: Matrix2
  @Binding var x: SIMD2<Double>
  var showsKernel: Bool

  var animatableData: AnimatableMatrix {
    get { AnimatableMatrix(matrix) }
    set { matrix = newValue.matrix }
  }

  var body: some View {
    GeometryReader { proxy in
      let mapping = PlaneMapping(size: proxy.size, extent: 1.8)
      Canvas { context, size in
        context.drawGrid(mapping, size: size)
        context.drawMappedCircle(mapping, matrix: .identity, stroke: Theme.neutral.opacity(0.8), fill: Theme.neutral.opacity(0.05))
        if showsKernel, let kernel = matrix.kernelDirection {
          context.drawLine(through: .zero, direction: kernel, in: mapping, size: size, color: Theme.dual, lineWidth: 5)
          context.drawLine(through: x, direction: kernel, in: mapping, size: size, color: Theme.neutral.opacity(0.5), lineWidth: 1.5, dash: [6, 6])
          context.draw(
            Text("ker(A)").font(.system(.callout, design: .serif).italic().weight(.semibold)).foregroundStyle(Theme.dual),
            at: mapping.point(kernel * 1.45 + SIMD2(0.28, 0))
          )
        }
        context.drawVector(x, in: mapping, color: Theme.neutral, lineWidth: 5, label: "x")
      }
      .contentShape(.rect)
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          let v = mapping.vector(at: value.location)
          x = SIMD2(v.x.clamped(to: -1.6...1.6), v.y.clamped(to: -1.6...1.6))
        }
      )
    }
    .accessibilityElement()
    .accessibilityLabel("Domain vector x")
    .accessibilityValue("\(x.x.fixedText()), \(x.y.fixedText())")
    .accessibilityAdjustableAction { direction in
      let angle = (direction == .increment ? 15.0 : -15.0).degreesToRadians
      x = SIMD2(x.x * cos(angle) - x.y * sin(angle), x.x * sin(angle) + x.y * cos(angle))
    }
  }
}

/// The transformed grid, the image of the unit circle, Ax, and (for rank-deficient maps) the image.
private struct CodomainView: View, Animatable {
  var matrix: Matrix2
  var x: SIMD2<Double>
  var showsImage: Bool

  var animatableData: AnimatableMatrix {
    get { AnimatableMatrix(matrix) }
    set { matrix = newValue.matrix }
  }

  var body: some View {
    Canvas { context, size in
      let mapping = PlaneMapping(size: size, extent: 1.8)
      context.drawGrid(mapping, size: size, color: Theme.grid.opacity(0.5))
      context.drawGrid(mapping, size: size, matrix: matrix, color: Theme.gridStrong)
      if showsImage, let image = matrix.imageDirection {
        context.drawLine(through: .zero, direction: image, in: mapping, size: size, color: Theme.dual, lineWidth: 5)
        context.draw(
          Text("im(A)").font(.system(.callout, design: .serif).italic().weight(.semibold)).foregroundStyle(Theme.dual),
          at: mapping.point(image * 1.45 + SIMD2(0, 0.22))
        )
      }
      context.drawMappedCircle(mapping, matrix: matrix, stroke: Theme.neutral.opacity(0.9), fill: Theme.neutral.opacity(0.05))
      context.drawVector(matrix.apply(x), in: mapping, color: Theme.neutral, lineWidth: 5, label: "Ax")
    }
    .accessibilityElement()
    .accessibilityLabel("Image A x")
    .accessibilityValue("\(matrix.apply(x).x.fixedText()), \(matrix.apply(x).y.fixedText())")
  }
}

/// Rank, kernel, image, and invertibility, labeled after the geometry makes them obvious.
private struct MapPropertiesView: View {
  var matrix: Matrix2
  var isRevealed: Bool

  var body: some View {
    let properties = LinearMapProperties(matrix: matrix)
    let singular = matrix.singularValues
    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
      row("Rank", "\(properties.rank)")
      row("ker(A)", properties.rank == 2 ? "{0}" : "a line", tint: properties.rank == 2 ? nil : Theme.dual)
      row("im(A)", properties.rank == 2 ? "all of W" : "a line", tint: properties.rank == 2 ? nil : Theme.dual)
      row("Injective", properties.isInjective ? "yes" : "no")
      row("Surjective", properties.isSurjective ? "yes" : "no (onto R²)")
      row("Invertible", properties.isInvertible ? "yes" : "no")
      row("σ₁, σ₂", "\(singular.0.fixedText()), \(singular.1.fixedText())")
    }
    .font(.callout)
    .opacity(isRevealed ? 1 : 0)
    .fixedSize()
  }

  private func row(_ label: String, _ value: String, tint: Color? = nil) -> some View {
    GridRow {
      Text(label)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .font(.caption.weight(.semibold))
      Text(value)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint ?? Theme.neutral)
    }
    .accessibilityElement(children: .combine)
  }
}

/// Interpolates a 2×2 matrix component-wise for morphing animations.
struct AnimatableMatrix: VectorArithmetic {
  var m11 = 0.0, m12 = 0.0, m21 = 0.0, m22 = 0.0

  init(_ matrix: Matrix2) {
    m11 = matrix.m11; m12 = matrix.m12; m21 = matrix.m21; m22 = matrix.m22
  }

  init() {}

  var matrix: Matrix2 { Matrix2(m11: m11, m12: m12, m21: m21, m22: m22) }

  static var zero: Self { Self() }

  static func + (lhs: Self, rhs: Self) -> Self {
    var r = Self()
    r.m11 = lhs.m11 + rhs.m11; r.m12 = lhs.m12 + rhs.m12
    r.m21 = lhs.m21 + rhs.m21; r.m22 = lhs.m22 + rhs.m22
    return r
  }

  static func - (lhs: Self, rhs: Self) -> Self {
    var r = Self()
    r.m11 = lhs.m11 - rhs.m11; r.m12 = lhs.m12 - rhs.m12
    r.m21 = lhs.m21 - rhs.m21; r.m22 = lhs.m22 - rhs.m22
    return r
  }

  mutating func scale(by rhs: Double) {
    m11 *= rhs; m12 *= rhs; m21 *= rhs; m22 *= rhs
  }

  var magnitudeSquared: Double { m11 * m11 + m12 * m12 + m21 * m21 + m22 * m22 }
}
