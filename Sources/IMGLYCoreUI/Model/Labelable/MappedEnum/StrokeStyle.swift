import Foundation

@_spi(Internal) public enum StrokeStyle: String, MappedEnum {
  case solid = "Solid"
  case dashed = "Dashed"
  case dashedRound = "DashedRound"
  case longDashed = "LongDashed"
  case longDashedRound = "LongDashedRound"
  case dotted = "Dotted"

  @_spi(Internal) public var description: String {
    switch self {
    case .solid: "Solid"
    case .dashed: "Dashed"
    case .dashedRound: "Dashed Round"
    case .longDashed: "Long Dashed"
    case .longDashedRound: "Long Dashed Round"
    case .dotted: "Dotted"
    }
  }

  @_spi(Internal) public var imageName: String? { nil }
}
