import Foundation

// This parser was generated with QuickType.

struct Manifest: Codable {
  let id, version, schemaVersion: String
  let assets: [ManifestAssets]
}

struct ManifestAssets: Codable {
  let type: String
  let assets: [Font]
}

struct Font: Codable, Equatable {
  let id, fontFamily: String
  let fontWeight: FontWeightUnion
  let fontPath: String
  let fontStyle: FontStyle?
}

enum FontStyle: String, Codable {
  case italic
}

enum FontWeightUnion: Codable, Equatable {
  case enumeration(FontWeightEnum)
  case integer(Int)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let x = try? container.decode(Int.self) {
      self = .integer(x)
      return
    }
    if let x = try? container.decode(FontWeightEnum.self) {
      self = .enumeration(x)
      return
    }
    throw DecodingError.typeMismatch(
      FontWeightUnion.self,
      DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for FontWeightUnion")
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .enumeration(x):
      try container.encode(x)
    case let .integer(x):
      try container.encode(x)
    }
  }
}

enum FontWeightEnum: String, Codable {
  case bold
  case light
  case medium
  case normal
}
