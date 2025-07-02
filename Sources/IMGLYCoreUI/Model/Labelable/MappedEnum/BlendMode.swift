import Foundation

@_spi(Internal) public enum BlendMode: String, MappedEnum {
  case passThrough = "PassThrough"
  case normal = "Normal"
  case darken = "Darken"
  case multiply = "Multiply"
  case colorBurn = "ColorBurn"
  case lighten = "Lighten"
  case screen = "Screen"
  case colorDodge = "ColorDodge"
  case overlay = "Overlay"
  case softLight = "SoftLight"
  case hardLight = "HardLight"
  case difference = "Difference"
  case exclusion = "Exclusion"
  case hue = "Hue"
  case saturation = "Saturation"
  case color = "Color"
  case luminosity = "Luminosity"

  @_spi(Internal) public var description: String {
    switch self {
    case .passThrough: "Pass Through"
    case .normal: "Normal"
    case .darken: "Darken"
    case .multiply: "Multiply"
    case .colorBurn: "Color Burn"
    case .lighten: "Lighten"
    case .screen: "Screen"
    case .colorDodge: "Color Dodge"
    case .overlay: "Overlay"
    case .softLight: "Soft Light"
    case .hardLight: "Hard Light"
    case .difference: "Difference"
    case .exclusion: "Exclusion"
    case .hue: "Hue"
    case .saturation: "Saturation"
    case .color: "Color"
    case .luminosity: "Luminosity"
    }
  }

  @_spi(Internal) public var imageName: String? { nil }
}
