import IMGLYEngine
import SwiftUI

struct CameraCanvasView: View {
  @ObservedObject var interactor: CameraCanvasInteractor

  var body: some View {
    if let engine = interactor.engine {
      Canvas(engine: engine)
        .aspectRatio(Double(interactor.canvasWidth) / Double(interactor.canvasHeight), contentMode: .fit)
    }
  }
}
