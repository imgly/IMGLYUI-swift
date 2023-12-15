import Foundation

@_spi(Internal) public protocol MappedEnum: MappedType, RawRepresentable<String>, CaseIterable, Labelable,
  IdentifiableByHash {}
