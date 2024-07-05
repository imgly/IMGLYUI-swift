import IMGLYEngine

@_spi(Internal) extension TextCase: Labelable {
  @_spi(Internal) public var description: String {
    switch self {
    case .normal: return "-"
    case .uppercase: return "AG"
    case .lowercase: return "ag"
    case .titlecase: return "Ag"
    @unknown default: return "-"
    }
  }

  @_spi(Internal) public var imageName: String? {
    nil
  }
}
