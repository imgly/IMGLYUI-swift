import Foundation
import struct SwiftUI.LocalizedStringKey
@_spi(Internal) import IMGLYCoreUI

struct ExportSheetState {
  var isPresented: Bool
  var state: ExportView.State?

  /// Hide sheet.
  init() {
    isPresented = false
    state = nil
  }

  /// Show sheet with `state`.
  init(_ state: ExportView.State) {
    isPresented = true
    self.state = state
  }
}
