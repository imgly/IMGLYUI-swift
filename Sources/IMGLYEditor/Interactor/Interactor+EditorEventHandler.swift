import Foundation
@_spi(Internal) import IMGLYCoreUI

extension Interactor: EditorEventHandler {
  @_spi(Internal) public func send(_ event: EditorEvent) {
    switch event {
    case let .shareFile(url):
      // Fix `.tintAdjustmentMode` to stay `.normal` when export sheet was presented.
      delayIfNecessary(hideExportSheet() || hideSheet()) { [weak self] in
        self?.activityItem = .init(items: url)
      }
    case let .exportProgress(value):
      showExportSheet(.exporting(value) { [weak self] in
        self?.cancelExport()
        self?.hideExportSheet()
      })
    case let .exportCompleted(action):
      showExportSheet(.completed { [weak self] in
        action()
        self?.hideExportSheet() // Must be run after `action()` in case action contains `.shareFile` event!
      })
    }
  }

  private func delayIfNecessary(_ shouldDelay: Bool, action: @escaping () -> Void) {
    if shouldDelay {
      Task {
        try await Task.sleep(for: .milliseconds(1000))
        action()
      }
    } else {
      action()
    }
  }

  func showExportSheet(_ state: ExportView.State) {
    delayIfNecessary(hideSheet()) { [weak self] in
      self?.export = .init(state)
    }
  }

  @discardableResult func hideExportSheet() -> Bool {
    let wasPresented = export.isPresented
    if export.isPresented {
      export = .init()
    }
    return wasPresented
  }

  @discardableResult func hideSheet() -> Bool {
    let wasPresented = sheet.isPresented
    if sheet.isPresented {
      sheet = .init()
    }
    return wasPresented
  }
}
