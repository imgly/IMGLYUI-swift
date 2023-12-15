import IMGLYEngine

@_spi(Internal) public extension AssetDefinition {
  convenience init(id: String, meta: AssetMeta) {
    self.init(id: id, meta: meta.mapKeys { $0.rawValue } uniquingKeysWith: { first, _ in first })
  }
}
