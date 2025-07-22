@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

public extension Postcard.Icon {
  /// An icon that displays the currently selected selection color.
  struct SelectionColors: View {
    public init() {}

    public var body: some View {
      SelectionColorsIcon()
    }
  }

  /// An icon that displays the currently selected color.
  struct Color: View {
    let id: DesignBlockID?

    public init(id: DesignBlockID?) {
      self.id = id
    }

    public var body: some View {
      FillColorIcon()
        .imgly.selection(id)
    }
  }

  /// An icon that displays the currently selected font.
  struct Font: View {
    let id: DesignBlockID?

    public init(id: DesignBlockID?) {
      self.id = id
    }

    public var body: some View {
      FontIcon()
        .imgly.selection(id)
    }
  }

  /// An icon that displays the currently selected font size.
  struct FontSize: View {
    let id: DesignBlockID?

    public init(id: DesignBlockID?) {
      self.id = id
    }

    public var body: some View {
      FontSizeIcon()
        .imgly.selection(id)
    }
  }
}
