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
    case .passThrough: return "Pass Through"
    case .normal: return "Normal"
    case .darken: return "Darken"
    case .multiply: return "Multiply"
    case .colorBurn: return "Color Burn"
    case .lighten: return "Lighten"
    case .screen: return "Screen"
    case .colorDodge: return "Color Dodge"
    case .overlay: return "Overlay"
    case .softLight: return "Soft Light"
    case .hardLight: return "Hard Light"
    case .difference: return "Difference"
    case .exclusion: return "Exclusion"
    case .hue: return "Hue"
    case .saturation: return "Saturation"
    case .color: return "Color"
    case .luminosity: return "Luminosity"
    }
  }

  @_spi(Internal) public var imageName: String? { nil }
}
