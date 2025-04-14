import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

extension Interactor: EditorEventHandler {
  @_spi(Internal) public func send(_ event: EditorEvent) {
    do {
      try handle(event)
    } catch {
      handleError(error)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  @_spi(Internal) public func handle(_ event: EditorEvent) throws {
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

    // MARK: - Sheet
    case let event as EditorEvents.Sheet.Open:
      try openSheet(event)
    case is EditorEvents.Sheet.Close:
      hideSheet()

    // MARK: - Selection
    case is EditorEvents.Selection.EnterTextEditMode:
      pause()
      clampPlayheadPositionToSelectedClip()
      setEditMode(.text)
    case is EditorEvents.Selection.Duplicate:
      pause()
      clampPlayheadPositionToSelectedClip()
      bottomBarButtonTapped(for: .duplicate)
    case is EditorEvents.Selection.Split:
      pause()
      splitSelectedClipAtPlayheadPosition()
    case is EditorEvents.Selection.MoveAsClip,
         is EditorEvents.Selection.MoveAsOverlay:
      pause()
      toggleSelectedClipIsInBackgroundTrack()
    case is EditorEvents.Selection.EnterGroup:
      pause()
      if let group = selection?.blocks.first {
        try engine?.block.enterGroup(group)
      }
    case is EditorEvents.Selection.SelectGroup:
      pause()
      clampPlayheadPositionToSelectedClip()
      if let child = selection?.blocks.first {
        try engine?.block.exitGroup(child)
      }
    case is EditorEvents.Selection.Delete:
      pause()
      bottomBarButtonTapped(for: .delete)

    // MARK: - AddFrom
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

  // swiftlint:disable:next cyclomatic_complexity
  private func openSheet(_ event: EditorEvents.Sheet.Open) throws {
    pause()

    switch event.type {
    case let sheet as SheetTypes.Custom:
      let content = sheetContentForSelection
      self.sheet = .init(sheet, content)
    case let sheet as SheetTypes.LibraryAdd:
      try engine?.block.deselectAll()
      self.sheet = .init(sheet)
    case let sheet as SheetTypes.LibraryReplace:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Voiceover:
      clampPlayheadPositionToSelectedClip()
      if selection?.blocks.first == nil {
        openVoiceOver(style: sheet.style)
      } else {
        editVoiceOver(style: sheet.style)
      }
    case let sheet as SheetTypes.Reorder:
      self.sheet = .init(sheet)
    case let sheet as SheetTypes.Adjustments:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContent(sheet.id) ?? sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Filter:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContent(sheet.id) ?? sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Effect:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContent(sheet.id) ?? sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Blur:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContent(sheet.id) ?? sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Crop:
      clampPlayheadPositionToSelectedClip()
      cropSheetTypeEvent = sheet
      if behavior.unselectedPageCrop, try engine?.block.getType(sheet.id) == DesignBlockType.page.rawValue {
        // Enter crop mode action
        try engine?.block.overrideAndRestore(sheet.id, scope: .key(.editorSelect)) {
          try engine?.block.select($0)
        }
        zoomToPage(withAdditionalPadding: 24)
        exitCropModeAction = { [weak self] in
          self?.zoomToPage(withAdditionalPadding: 0)
          try self?.engine?.block.setSelected(sheet.id, selected: false)
        }
        Task {
          try await Task.sleep(for: .milliseconds(50))
          setEditMode(.crop)
        }
      } else {
        setEditMode(.crop)
      }
    case let sheet as SheetTypes.Layer:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.FormatText:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Shape:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.FillStroke:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.Volume:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    case let sheet as SheetTypes.TextBackground:
      clampPlayheadPositionToSelectedClip()
      if let content = sheetContentForSelection {
        self.sheet = .init(sheet, content)
      }
    default:
      print("Unhandled sheet type \(event.type)")
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
      self?.export.show(state)
    }
  }

  @discardableResult func hideExportSheet() -> Bool {
    let wasPresented = export.isPresented
    if export.isPresented {
      export.hide()
    }
    return wasPresented
  }

  @discardableResult func hideSheet() -> Bool {
    let wasPresented = sheet.isPresented
    if sheet.isPresented {
      export.hide()
    }
    return wasPresented
  }
}
