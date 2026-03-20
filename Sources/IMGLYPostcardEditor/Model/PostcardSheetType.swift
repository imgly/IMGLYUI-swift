import IMGLYEngine
@_spi(Internal) import IMGLYEditor

public extension Postcard.SheetType {
  /// Creates a ``IMGLYEditor/SheetType`` that is used to change the design colors.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``IMGLYEditor/SheetStyle/default(isFloating:detent:detents:)``
  /// style is
  /// used.
  /// - Returns: The created ``IMGLYEditor/SheetTypes`` design colors sheet type.
  static func designColors(style: SheetStyle = .default()) -> some SheetType {
    .designColors(style: style)
  }

  /// Creates a ``IMGLYEditor/SheetType`` that is used to change the color of a given block.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``IMGLYEditor/SheetStyle/only(isFloating:detent:)`` style is
  /// used.
  ///   - id: The id of the design block to apply the color.
  ///   - colorPalette: The available colors.
  /// - Returns: The created ``IMGLYEditor/SheetTypes`` greeting colors sheet type.
  static func greetingColors(style: SheetStyle = .only(detent: .imgly.tiny), id: DesignBlockID,
                             colorPalette: [NamedColor]? = nil) -> some SheetType {
    .greetingColors(style: style, id: id, colorPalette: colorPalette)
  }

  /// Creates a ``IMGLYEditor/SheetType`` that is used to change the font of a given block.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``IMGLYEditor/SheetStyle/default(isFloating:detent:detents:)``
  /// style is
  /// used.
  ///   - id: The id of the design block to apply the font.
  ///   - fontFamilies: The available font families.
  /// - Returns: The created ``IMGLYEditor/SheetTypes`` greeting font sheet type.
  static func greetingFont(style: SheetStyle = .default(), id: DesignBlockID,
                           fontFamilies: [String]? = nil) -> some SheetType {
    .greetingFont(style: style, id: id, fontFamilies: fontFamilies)
  }

  /// Creates a ``IMGLYEditor/SheetType`` that is used to change the font size of a given block.
  /// - Parameters:
  ///   - style: The style of the sheet. By default, the ``IMGLYEditor/SheetStyle/only(isFloating:detent:)`` style is
  /// used.
  ///   - id: The id of the design block to apply the font size.
  /// - Returns: The created ``IMGLYEditor/SheetTypes`` greeting size sheet type.
  static func greetingSize(style: SheetStyle = .only(detent: .imgly.tiny), id: DesignBlockID) -> some SheetType {
    .greetingSize(style: style, id: id)
  }
}
