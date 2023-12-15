import Foundation
@_spi(Internal) import IMGLYCoreUI

struct AssetSelection {
  let identifier: String?
  let assetURL: String?
  let metadata: [String: String]?
  let sourceID: String?
  let id: Interactor.BlockID?

  init(
    identifier: String? = nil,
    assetURL: String? = nil,
    metadata: [String: String]? = nil,
    sourceID: String? = nil,
    id: Interactor.BlockID? = nil
  ) {
    self.identifier = identifier
    self.assetURL = assetURL
    self.metadata = metadata
    self.sourceID = sourceID
    self.id = id
  }
}

extension AssetSelection: MappedType {}
