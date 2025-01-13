import Foundation
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

extension Interactor: EditorEventHandler {
  // swiftlint:disable:next cyclomatic_complexity
  @_spi(Internal) public func send(_ event: EditorEvent) {
    switch event {
    case let event as EditorEvents.ShareFile:
      // Fix `.tintAdjustmentMode` to stay `.normal` when export sheet was presented.
      delayIfNecessary(hideExportSheet() || hideSheet()) { [weak self] in
        self?.shareItem = .url([event.url])
      }
    case let event as EditorEvents.Export.Progress:
      showExportSheet(.exporting(event.progress) { [weak self] in
        self?.cancelExport()
        self?.hideExportSheet()
      })
    case let event as EditorEvents.Export.Completed:
      showExportSheet(.completed { [weak self] in
        event.action()
        self?.hideExportSheet() // Must be run after `action()` in case action contains `.shareFile` event!
      })
    case let event as EditorEvents.Sheet.Open:
      switch event.type {
      case let sheet as SheetTypes.Custom:
        bottomBarButtonTapped(for: .sheet(.init {
          AnyView(erasing: sheet.content())
        }), style: sheet.style)
      case let sheet as SheetTypes.LibraryAdd:
        bottomBarButtonTapped(for: .sheet(.init {
          AnyView(erasing: sheet.content())
        }), style: sheet.style)
      case let sheet as SheetTypes.Voiceover:
        openVoiceOver(style: sheet.style)
      case let sheet as SheetTypes.Reorder:
        bottomBarButtonTapped(for: .reorder, style: sheet.style)
      case let sheet as SheetTypes.Adjustments:
        bottomBarButtonTapped(for: .adjustments(sheet.id), style: sheet.style)
      case let sheet as SheetTypes.Filter:
        bottomBarButtonTapped(for: .filter(sheet.id), style: sheet.style)
      case let sheet as SheetTypes.Effect:
        bottomBarButtonTapped(for: .effect(sheet.id), style: sheet.style)
      case let sheet as SheetTypes.Blur:
        bottomBarButtonTapped(for: .blur(sheet.id), style: sheet.style)
      case let sheet as SheetTypes.Crop:
        bottomBarButtonTapped(for: .crop(sheet.id, enter: .init { [weak self] in
          self?.zoomToPage(withAdditionalPadding: 24)
        }, exit: .init { [weak self] in
          self?.zoomToPage(withAdditionalPadding: 0)
          try self?.engine?.block.setSelected(sheet.id, selected: false)
        }), style: sheet.style)
      default:
        print("Unhandled sheet type \(event.type)")
      }
    case is EditorEvents.Sheet.Close:
      hideSheet()
    case let event as EditorEvents.AddFrom.PhotoRoll:
      openImagePicker(event.assetSourceIDs)
    case let event as EditorEvents.AddFrom.SystemCamera:
      openSystemCamera(event.assetSourceIDs)
    case let event as EditorEvents.AddFrom.IMGLYCamera:
      openCamera(event.assetSourceIDs)
    default:
      print("Unhandled event \(event)")
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
