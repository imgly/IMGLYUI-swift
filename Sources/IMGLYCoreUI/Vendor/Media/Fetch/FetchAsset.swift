import Photos
import SwiftUI

/// Fetches a single asset
@propertyWrapper
struct FetchAsset: DynamicProperty {
  @ObservedObject
  private(set) var observer: AssetObserver

  /// Represents the fetched asset
  @_spi(Internal) public var wrappedValue: MediaAsset {
    MediaAsset(asset: observer.asset)
  }
}

extension FetchAsset {
  /// Instantiates the fetch with an existing `PHAsset`
  /// - Parameter asset: The asset
  @_spi(Internal) public init(_ asset: PHAsset) {
    let observer = AssetObserver(asset: asset)
    self.init(observer: observer)
  }
}

/// Represents the result of a `FetchAsset` request.
struct MediaAsset {
  @_spi(Internal) public private(set) var asset: PHAsset?

  @_spi(Internal) public init(asset: PHAsset?) {
    self.asset = asset
  }
}

final class AssetObserver: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
  @Published
  var asset: PHAsset?

  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }

  init(asset: PHAsset) {
    self.asset = asset
    super.init()
    PHPhotoLibrary.shared().register(self)
  }

  func photoLibraryDidChange(_ changeInstance: PHChange) {
    guard let asset else { return }
    self.asset = changeInstance.changeDetails(for: asset)?.objectAfterChanges
  }
}
