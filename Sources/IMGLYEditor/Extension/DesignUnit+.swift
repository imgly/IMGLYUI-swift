import IMGLYEngine

extension DesignUnit {
  var description: String {
    switch self {
    case .mm:
      "mm"
    case .px:
      "px"
    case .in:
      "in"
    default: ""
    }
  }

  var label: String {
    switch self {
    case .in: "Inch"
    case .px: "Pixel"
    case .mm: "Millimeter"
    default: ""
    }
  }
}
