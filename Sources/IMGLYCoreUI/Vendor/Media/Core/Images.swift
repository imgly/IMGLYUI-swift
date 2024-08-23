import Photos

@_spi(Internal) public extension PHAssetCollectionSubtype {
  /// A convenience property that returns the associated SFSymbol image for the specified collection subtype
  var systemImageName: String {
    switch self {
    case .albumCloudShared: "rectangle.stack.badge.person.crop"
    case .albumImported: "square.and.arrow.down"
    case .albumMyPhotoStream: "heart.text.square"
    case .albumSyncedAlbum: "rectangle.stack.badge.person.crop"
    case .albumSyncedEvent: "mappin.and.ellipse"
    case .albumSyncedFaces: "person.crop.circle"
    case .smartAlbumAllHidden: "eye.slash"
    case .smartAlbumAnimated: "square.stack.3d.forward.dottedline"
    case .smartAlbumBursts: "square.stack.3d.down.right"
    case .smartAlbumDepthEffect, .smartAlbumSelfPortraits: "cube"
    case .smartAlbumFavorites: "heart"
    case .smartAlbumLivePhotos: "livephoto"
    case .smartAlbumLongExposures: "plusminus.circle"
    case .smartAlbumPanoramas: "pano"
    case .smartAlbumRecentlyAdded: "clock"
    case .smartAlbumScreenshots: "camera.viewfinder"
    case .smartAlbumSlomoVideos: "slowmo"
    case .smartAlbumTimelapses: "timelapse"
    case .smartAlbumUnableToUpload: "icloud.and.arrow.up"
    case .smartAlbumUserLibrary: "photo.on.rectangle"
    case .smartAlbumVideos: "video"
    default: "rectangle.stack"
    }
  }
}

@_spi(Internal) public extension PHCollectionListSubtype {
  /// A convenience property that returns the associated SFSymbol image for the specified list subtype
  var systemImageName: String {
    switch self {
    case .smartFolderEvents: "mappin.and.ellipse"
    case .smartFolderFaces: "person.crop.circle"
    default: "folder"
    }
  }
}
