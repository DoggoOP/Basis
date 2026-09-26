import SwiftUI

/// The edge of a panel that touches the hinge.
enum HingeEdge {
  case leading, trailing, top, bottom

  /// Aligns panel content to the corner farthest from the hinge, starting at the top.
  var outerAlignment: Alignment {
    switch self {
    case .trailing, .bottom: .topLeading
    case .leading: .topTrailing
    case .top: .bottomLeading
    }
  }

  var horizontalAlignment: HorizontalAlignment {
    self == .leading ? .trailing : .leading
  }

  var textAlignment: TextAlignment {
    self == .leading ? .trailing : .leading
  }

  /// Whether the hinge runs vertically on screen.
  var isVerticalHinge: Bool { self == .leading || self == .trailing }
}

extension EnvironmentValues {
  @Entry var hingeEdge: HingeEdge = .trailing
}

/// Maps a panel's hinge-relative coordinates to view points and back.
///
/// `away` is the distance from the hinge line; `along` runs in the hinge
/// direction h, measured from the panel's midpoint.
struct PanelGeometry {
  var size: CGSize
  var edge: HingeEdge

  var origin: CGPoint {
    switch edge {
    case .trailing: CGPoint(x: size.width, y: size.height / 2)
    case .leading: CGPoint(x: 0, y: size.height / 2)
    case .bottom: CGPoint(x: size.width / 2, y: size.height)
    case .top: CGPoint(x: size.width / 2, y: 0)
    }
  }

  var awayDirection: CGVector {
    switch edge {
    case .trailing: CGVector(dx: -1, dy: 0)
    case .leading: CGVector(dx: 1, dy: 0)
    case .bottom: CGVector(dx: 0, dy: -1)
    case .top: CGVector(dx: 0, dy: 1)
    }
  }

  /// Screen direction of h. With a in the leading panel and b in the trailing one,
  /// a × b points this way.
  var hingeDirection: CGVector {
    edge.isVerticalHinge ? CGVector(dx: 0, dy: -1) : CGVector(dx: 1, dy: 0)
  }

  /// Distance from the hinge to the opposite edge.
  var depth: CGFloat { edge.isVerticalHinge ? size.width : size.height }

  /// Length of the hinge edge.
  var span: CGFloat { edge.isVerticalHinge ? size.height : size.width }

  func point(away: CGFloat, along: CGFloat) -> CGPoint {
    CGPoint(
      x: origin.x + awayDirection.dx * away + hingeDirection.dx * along,
      y: origin.y + awayDirection.dy * away + hingeDirection.dy * along
    )
  }

  func coordinates(of point: CGPoint) -> (away: CGFloat, along: CGFloat) {
    let dx = point.x - origin.x, dy = point.y - origin.y
    return (
      dx * awayDirection.dx + dy * awayDirection.dy,
      dx * hingeDirection.dx + dy * hingeDirection.dy
    )
  }
}
