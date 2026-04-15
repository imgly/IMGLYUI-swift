import IMGLYCoreUI
import SwiftUI

/// A minimal editor without solution-specific defaults for building completely custom editor experiences.
public struct Editor: View {
  private let settings: EngineSettings

  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI()
      .navigationTitle("")
      .imgly.editor(settings)
  }
}

struct Editor_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
