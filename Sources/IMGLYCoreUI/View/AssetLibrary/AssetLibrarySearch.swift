@_spi(Internal) import IMGLYCore
import SwiftUI

@_spi(Internal) public class AssetLibrarySearchState: ObservableObject {
  @Published @_spi(Internal) public var isPresented: Bool = false
  @Published @_spi(Internal) public private(set) var prompt: Text?

  @_spi(Internal) public init(isPresented: Bool = false, prompt: Text? = nil) {
    self.isPresented = isPresented
    self.prompt = prompt
  }

  func setPrompt(for title: LocalizedStringResource) {
    prompt = .init(.imgly.localized("ly_img_editor_asset_library_label_search_placeholder \(title)"))
  }
}

typealias AssetLibrarySearchQuery = Debouncer<AssetLoader.QueryData>
