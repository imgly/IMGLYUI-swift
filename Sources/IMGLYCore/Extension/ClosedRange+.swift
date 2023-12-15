import Foundation

@_spi(Internal) public extension ClosedRange where Bound: AdditiveArithmetic {
  var length: Bound {
    upperBound - lowerBound
  }
}
