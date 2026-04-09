import IMGLYEditor
import SwiftUI

@available(*, unavailable, message: """
PostcardEditor is no longer supported. Please migrate to the new Starter Kit pattern. \
See the migration guide: https://img.ly/docs/cesdk/ios/to-v1-73-ab14fb/
""")
public struct PostcardEditor: View {
  private let settings: EngineSettings

  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    Editor(settings)
  }
}
