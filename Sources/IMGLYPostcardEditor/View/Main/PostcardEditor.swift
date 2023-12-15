@_spi(Internal) import IMGLYEditor
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

@_exported import IMGLYEditor

enum Page: Int, Localizable {
  case design, write

  var description: String {
    switch self {
    case .design: return "Design"
    case .write: return "Write"
    }
  }

  var previous: Page? { Self(rawValue: index - 1) }
  var next: Page? { Self(rawValue: index + 1) }
  var index: Int { rawValue }
}

public struct PostcardEditor: View {
  public static let defaultScene = Bundle.module.url(forResource: "postcard-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  private let settings: EngineSettings

  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    ContentView()
      .imgly.editor(settings, behavior: .postcard)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadScene(from: Self.defaultScene)(engine)
          return
        }
        try await onCreate(engine)
      }
  }
}

private struct ContentView: View {
  @EnvironmentObject private var interactor: Interactor

  var page: Page? { Page(rawValue: interactor.page) }

  var isBackButtonHidden: Bool { !interactor.isEditing || page?.previous != nil }

  var body: some View {
    EditorUI()
      .navigationBarBackButtonHidden(isBackButtonHidden)
      .preference(key: BackButtonHiddenKey.self, value: isBackButtonHidden)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if interactor.isEditing, let previousPage = page?.previous {
            PageNavigationButton(to: previousPage, direction: .backward)
          }
        }
        ToolbarItemGroup(placement: .principal) {
          HStack {
            UndoRedoButtons()
            Spacer().frame(maxWidth: 42)
            PreviewButton()
          }
          .labelStyle(.adaptiveIconOnly)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          if let nextPage = page?.next, interactor.isEditing {
            PageNavigationButton(to: nextPage, direction: .forward)
          } else {
            ExportButton()
              .labelStyle(.adaptiveIconOnly)
          }
        }
      }
  }
}

struct PostcardUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
