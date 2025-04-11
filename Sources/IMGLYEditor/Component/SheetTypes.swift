import IMGLYEngine
import SwiftUI

/// A type that represents a sheet used in the editor.
/// - Note: Avoid conforming custom types to this protocol. If you want to create a custom sheet use
/// ``EditorEvent/openSheet(style:content:)`` instead.
public protocol SheetType {
  /// The style of the sheet.
  var style: SheetStyle { get }
}

protocol SheetTypeForDesignBlock: SheetType {
  var id: DesignBlockID { get }
}

/// A namespace for ``SheetType``s.
public enum SheetTypes {
  struct Custom: SheetType {
    let style: SheetStyle
    let content: () -> any View
  }
}

public extension SheetTypes {
  /// A sheet to display the ``AssetLibrary`` in order to add assets to the scene..
  struct LibraryAdd: SheetType {
    public let style: SheetStyle
    let content: () -> any View
  }

  /// A sheet to display the ``AssetLibrary`` in order to replace assets in the scene.
  struct LibraryReplace: SheetType {
    public let style: SheetStyle
    let content: () -> any View
  }

  /// A sheet that is used for voiceover recording.
  struct Voiceover: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to reorder videos on the background track.
  struct Reorder: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to make adjustments to design blocks with image and video fills.
  struct Adjustments: SheetTypeForDesignBlock {
    public let style: SheetStyle
    let id: DesignBlockID
  }

  /// A sheet that is used to set filters to design blocks with image and video fills.
  struct Filter: SheetTypeForDesignBlock {
    public let style: SheetStyle
    let id: DesignBlockID
  }

  /// A sheet that is used to set effects to design blocks with image and video fills.
  struct Effect: SheetTypeForDesignBlock {
    public let style: SheetStyle
    let id: DesignBlockID
  }

  /// A sheet that is used to set blurs to design blocks with image and video fills.
  struct Blur: SheetTypeForDesignBlock {
    public let style: SheetStyle
    let id: DesignBlockID
  }

  /// A sheet that is used to crop design blocks with image and video fills.
  struct Crop: SheetTypeForDesignBlock {
    public let style: SheetStyle
    let id: DesignBlockID
  }

  /// A sheet that is used to control the layering of design blocks.
  struct Layer: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to control formatting of text blocks.
  struct FormatText: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to control the shape of various blocks.
  struct Shape: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to control the fill and/or stroke of various blocks.
  struct FillStroke: SheetType {
    public let style: SheetStyle
  }

  /// A sheet that is used to control the volume of audio/video.
  struct Volume: SheetType {
    public let style: SheetStyle
  }
}

public extension SheetType where Self == SheetTypes.LibraryAdd {
  /// Creates a ``SheetType`` to add assets to the scene from the ``AssetLibrary`` configured with the
  /// ``IMGLY/assetLibrary(_:)`` view modifier.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/addAsset(detent:detents:)`` style is used.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``SheetTypes/LibraryAdd`` sheet type.
  static func libraryAdd(
    style: SheetStyle = .addAsset(),
    @ViewBuilder content: @escaping () -> any View
  ) -> Self {
    Self(style: style, content: content)
  }

  /// Creates a ``SheetType`` to add assets to the scene from a custom asset library defined by the provided `content`
  /// with an ``AssetLibraryBuilder`` independent of the ``AssetLibrary`` configured with the ``IMGLY/assetLibrary(_:)``
  /// view modifier.
  /// - Parameters:
  ///   - title: The title of the sheet.
  ///   - style: The style of the sheet. By default, the ``SheetStyle/addAsset(detent:detents:)`` style is used.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``SheetTypes/LibraryAdd`` sheet type.
  @MainActor
  static func libraryAdd(
    _ title: String,
    style: SheetStyle = .addAsset(),
    @AssetLibraryBuilder content: @escaping () -> AssetLibraryContent
  ) -> Self {
    Self(style: style, content: { AssetLibraryTab(title, content: content) { _ in EmptyView() } })
  }
}

public extension SheetType where Self == SheetTypes.LibraryReplace {
  /// Creates a ``SheetType`` to replace assets in the scene from the ``AssetLibrary`` configured with the
  /// ``IMGLY/assetLibrary(_:)`` view modifier.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/default(isFloating:detent:detents:)`` style is
  /// used.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``SheetTypes/LibraryReplace`` sheet type.
  static func libraryReplace(
    style: SheetStyle = .default(),
    @ViewBuilder content: @escaping () -> any View
  ) -> Self {
    Self(style: style, content: content)
  }

  /// Creates a ``SheetType`` to replace assets in the scene from a custom asset library defined by the provided
  /// `content` with an ``AssetLibraryBuilder`` independent of the ``AssetLibrary`` configured with the
  /// ``IMGLY/assetLibrary(_:)`` view modifier
  /// - Parameters:
  ///   - title: The title of the sheet.
  ///   - style: The style of the sheet. By default, the ``SheetStyle/default(isFloating:detent:detents:)`` style is
  /// used.
  ///   - content: The content of the sheet.
  /// - Returns: The created ``SheetTypes/LibraryReplace`` sheet type.
  @MainActor
  static func libraryReplace(
    _ title: String,
    style: SheetStyle = .default(),
    @AssetLibraryBuilder content: @escaping () -> AssetLibraryContent
  ) -> Self {
    Self(style: style, content: { AssetLibraryTab(title, content: content) { _ in EmptyView() } })
  }
}

public extension SheetType where Self == SheetTypes.Voiceover {
  /// Creates a ``SheetType`` that is used for voiceover recording.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  /// - Returns: The created ``SheetTypes/Voiceover`` sheet type.
  static func voiceover(style: SheetStyle = .only(detent: .imgly.medium)) -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.Reorder {
  /// Creates a ``SheetType`` that is used to reorder videos on the background track.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is
  /// - Returns: The created ``SheetTypes/Reorder`` sheet type.
  static func reorder(style: SheetStyle = .only(detent: .imgly.medium)) -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.Adjustments {
  /// Creates a ``SheetType`` that is used to make adjustments to design blocks with image and video fills
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  ///   - id: The id of the design block to apply the adjustments.
  /// - Returns: The created ``SheetTypes/Adjustments`` sheet type.
  static func adjustments(style: SheetStyle = .only(detent: .imgly.medium), id: DesignBlockID) -> Self {
    Self(style: style, id: id)
  }
}

public extension SheetType where Self == SheetTypes.Filter {
  /// Creates a ``SheetType`` that is used to set filters to design blocks with image and video fills.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  ///   - id: The id of the design block to apply the filter.
  /// - Returns: The created ``SheetTypes/Filter`` sheet type.
  static func filter(style: SheetStyle = .only(detent: .imgly.tiny), id: DesignBlockID) -> Self {
    Self(style: style, id: id)
  }
}

public extension SheetType where Self == SheetTypes.Effect {
  /// Creates a ``SheetType`` that is used to set effects to design blocks with image and video fills.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  ///   - id: The id of the design block to apply the effect.
  /// - Returns: The created ``SheetTypes/Effect`` sheet type.
  static func effect(style: SheetStyle = .only(detent: .imgly.tiny), id: DesignBlockID) -> Self {
    Self(style: style, id: id)
  }
}

public extension SheetType where Self == SheetTypes.Blur {
  /// Creates a ``SheetType`` that is used to set blurs to design blocks with image and video fills.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  ///   - id: The id of the design block to apply the blur.
  /// - Returns: The created ``SheetTypes/Blur`` sheet type.
  static func blur(style: SheetStyle = .only(detent: .imgly.tiny), id: DesignBlockID) -> Self {
    Self(style: style, id: id)
  }
}

public extension SheetType where Self == SheetTypes.Crop {
  /// Creates a ``SheetType`` that is used to crop design blocks with image and video fills.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``SheetStyle/default(isFloating:detent:detents:)`` style is
  /// used.
  ///   - id: The id of the design block to apply the crop.
  /// - Returns: The created ``SheetTypes/Crop`` sheet type.
  static func crop(
    style: SheetStyle = .default(detent: .imgly.small, detents: [.imgly.small, .imgly.large]),
    id: DesignBlockID
  ) -> Self {
    Self(style: style, id: id)
  }
}

public extension SheetType where Self == SheetTypes.Layer {
  /// Creates a ``SheetType`` that is used to control the layering of design blocks.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  /// - Returns: The created ``SheetTypes/Layer`` sheet type.
  static func layer(style: SheetStyle = .only(detent: .imgly.medium)) -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.FormatText {
  /// Creates a ``SheetType`` that is used to control formatting of text blocks.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  /// - Returns: The created ``SheetTypes/FormatText`` sheet type.
  static func formatText(style: SheetStyle = .only(detent: .imgly.medium)) -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.Shape {
  /// Creates a ``SheetType`` that is used to control the shape of various blocks.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/default(isFloating:detent:detents:)``
  /// style is used.
  /// - Returns: The created ``SheetTypes/Shape`` sheet type.
  static func shape(style: SheetStyle = .default(detent: .imgly.small, detents: [.imgly.tiny, .imgly.small]))
    -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.FillStroke {
  /// Creates a ``SheetType`` that is used to control the fill and/or stroke of various blocks.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/default(isFloating:detent:detents:)``
  /// style is used.
  /// - Returns: The created ``SheetTypes/FillStroke`` sheet type.
  static func fillStroke(style: SheetStyle = .default()) -> Self { Self(style: style) }
}

public extension SheetType where Self == SheetTypes.Volume {
  /// Creates a ``SheetType`` that is used to control the volume of audio/video.
  /// - Parameter style: The style of the sheet. By default, the ``SheetStyle/only(detent:)`` style is used.
  /// - Returns: The created ``SheetTypes/Volume`` sheet
  static func volume(style: SheetStyle = .only(detent: .imgly.tiny)) -> Self { Self(style: style) }
}
