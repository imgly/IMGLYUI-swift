import Foundation
import struct SwiftUI.LocalizedStringKey
@_spi(Internal) import IMGLYCoreUI

final class ExportSheetState: ObservableObject {
  @Published var isPresented: Bool
  @Published var state: ExportView.State?

  /// Hide sheet.
  init() {
    isPresented = false
    state = nil
  }

  func show(_ state: ExportView.State) {
    self.state = state
    isPresented = true
  }

  func hide() {
    state = nil
    isPresented = false
  }
}
