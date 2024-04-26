@preconcurrency import Combine
import Foundation
import IMGLYEngine

@MainActor
class AnyAssetLibraryInteractor: AssetLibraryInteractor {
  var isAddingAsset: Bool { interactor.isAddingAsset }

  func findAssets(sourceID: String, query: AssetQueryData) async throws -> AssetQueryResult {
    try await interactor.findAssets(sourceID: sourceID, query: query)
  }

  func getGroups(sourceID: String) async throws -> [String] {
    try await interactor.getGroups(sourceID: sourceID)
  }

  func getCredits(sourceID: String) -> AssetCredits? {
    interactor.getCredits(sourceID: sourceID)
  }

  func getLicense(sourceID: String) -> AssetLicense? {
    interactor.getLicense(sourceID: sourceID)
  }

  func addAsset(to sourceID: String, asset: AssetDefinition) async throws -> AssetDefinition {
    try await interactor.addAsset(to: sourceID, asset: asset)
  }

  func uploadAsset(to sourceID: String, asset: AssetUpload) async throws -> AssetResult {
    try await interactor.uploadAsset(to: sourceID, asset: asset)
  }

  func assetTapped(sourceID: String, asset: AssetResult) {
    interactor.assetTapped(sourceID: sourceID, asset: asset)
  }

  private let interactor: any AssetLibraryInteractor

  init(erasing interactor: some AssetLibraryInteractor) {
    self.interactor = interactor
    objectWillChange = interactor
      .objectWillChange
      .map { _ in }
      .eraseToAnyPublisher()
  }

  let objectWillChange: AnyPublisher<Void, Never>
}
