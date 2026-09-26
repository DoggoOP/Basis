import Foundation

extension Double {
  /// A fixed-precision, sign-prefixed value such as "+0.42".
  func signedText(fractionDigits: Int = 2) -> String {
    cleaned(fractionDigits: fractionDigits)
      .formatted(.number.precision(.fractionLength(fractionDigits)).sign(strategy: .always(includingZero: false)))
  }

  func fixedText(fractionDigits: Int = 2) -> String {
    cleaned(fractionDigits: fractionDigits).formatted(.number.precision(.fractionLength(fractionDigits)))
  }

  func degreesText(fractionDigits: Int = 1) -> String {
    fixedText(fractionDigits: fractionDigits) + "°"
  }

  func percentText() -> String {
    (self * 100).rounded().formatted(.number.precision(.fractionLength(0))) + "%"
  }
}
