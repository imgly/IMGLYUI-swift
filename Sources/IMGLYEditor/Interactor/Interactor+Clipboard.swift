@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import UIKit
import UniformTypeIdentifiers

/// Copy and paste through the system clipboard, in the format of the web editor, so a copy pastes in another editor,
/// another app and on another platform. While a text block is in edit mode, the engine's text input handles both.
extension Interactor {
  /// The last copy of this editor, which holds every resource of the blocks. A paste of the same copy uses it, so a
  /// copy that was too large for the clipboard still pastes here.
  struct ClipboardCopy {
    let id: String
    let blocks: String
    /// How often this editor pasted the copy, so each paste lands a step further from the copied blocks.
    var pasteCount = 0
  }

  /// What a paste reads from the clipboard. The read happens in the `paste:` command itself, as iOS asks for no
  /// permission there.
  struct ClipboardContent {
    let html: String?
    let string: String?
    /// The media items, whose files load from the start: a provider no longer loads once the command has returned.
    let media: [PastedMedia]
    /// Whether an item is a file of a type that the editor cannot add.
    let hasUnsupportedFile: Bool

    init(_ pasteboard: UIPasteboard) {
      self.init(
        providers: pasteboard.itemProviders,
        html: pasteboard.data(forPasteboardType: UTType.html.identifier).flatMap { String(data: $0, encoding: .utf8) },
        string: pasteboard.string,
      )
    }

    /// A drop passes only its item providers, so its text is never pasted.
    init(providers: [NSItemProvider], html: String? = nil, string: String? = nil) {
      self.html = html
      self.string = string
      var media: [PastedMedia] = []
      var hasUnsupportedFile = false
      for provider in providers {
        let types = provider.registeredTypeIdentifiers.compactMap(UTType.init)
        let candidates = types.compactMap { type in MediaKind(type).map { (type, $0) } }
        let preferred = candidates
          .first { type, _ in Interactor.preferredImageTypes.contains { type.conforms(to: $0) } }
        if let (type, kind) = preferred ?? candidates.first {
          media.append(.init(kind: kind, file: PastedFile(provider: provider, type: type)))
        } else if Interactor.isFile(types) {
          hasUnsupportedFile = true
        }
      }
      self.media = media
      self.hasUnsupportedFile = hasUnsupportedFile
    }
  }

  private static let readChunkSize: UInt = 1024 * 1024
  private static let maxWidthOfPage: Float = 0.8
  private static let creatorRole = "Creator"
  /// The step between the pastes of a copy, as Duplicate moves its copy.
  private static let pasteOffset: Float = 5

  /// Whether the selection may be copied, by the rules of the web editor: each block needs `lifecycle/duplicate`, and a
  /// page needs the role that manages pages.
  var canCopySelection: Bool {
    guard let engine, editMode != .text else { return false }
    let selected = engine.block.findAllSelected()
    guard !selected.isEmpty else { return false }
    let managesPages = (try? engine.editor.getRole()) == Self.creatorRole
    return selected.allSatisfy { id in
      let isPage = (try? engine.block.getType(id)) == DesignBlockType.page.rawValue
      return (!isPage || managesPages) && isAllowed(id, scope: .lifecycleDuplicate)
    }
  }

  var canCutSelection: Bool {
    guard canCopySelection, let engine else { return false }
    return engine.block.findAllSelected().allSatisfy { isAllowed($0, scope: .lifecycleDestroy) }
  }

  /// Whether the clipboard holds something that a paste can place. Reads only the types, so iOS asks for no
  /// permission.
  var canPaste: Bool {
    guard engine != nil, editMode != .text, (try? engine?.scene.getCurrentPage()) != nil else { return false }
    return pasteboard.numberOfItems > 0
  }

  /// Copies the selected blocks to the system clipboard and keeps a session copy. A cut deletes them once both saves
  /// are done.
  func copySelection(cut: Bool = false) {
    guard let engine, cut ? canCutSelection : canCopySelection else { return }
    let blocks = engine.block.findAllSelected()
    Task {
      do {
        try await writeClipboard(engine: engine, blocks: blocks)
        guard cut else { return }
        // The copied blocks go, not what is selected once both saves are done. Deleting a group deletes its
        // children, so a selected child can be gone already.
        try engine.delete(blocks.filter(engine.block.isValid))
      } catch {
        handleError(error)
      }
    }
  }

  private func writeClipboard(engine: Engine, blocks: [DesignBlockID]) async throws {
    let id = UUID().uuidString
    let textBlocks = try blocks.filter { try engine.block.getType($0) == DesignBlockType.text.rawValue }
    let text = try textBlocks.map { try engine.block.getString($0, property: "text/text") }.joined(separator: "\n")
    // Other apps and other engines read the formatting of the text from its HTML.
    let textHTML = try textBlocks.map { try engine.block.getTextAsHTML($0) }.joined()

    let session = try await engine.block.saveToString(
      blocks: blocks,
      allowedResourceSchemes: ClipboardBlocks.sessionSchemes,
    )
    lastClipboardCopy = ClipboardCopy(id: id, blocks: session)

    // The engine asks for every resource before it gets an answer, so each placeholder takes its index before the
    // first await.
    var resources: [Int: (url: String, resource: ClipboardBlocks.Resource)] = [:]
    var nextIndex = 0
    var budget = ClipboardBlocks.maxEmbeddedBytes
    var readFailed = false
    var portable: String?
    do {
      portable = try await engine.block.saveToString(
        blocks: blocks,
        allowedResourceSchemes: ClipboardBlocks.portableSchemes,
      ) { url, _ in
        let index = nextIndex
        nextIndex += 1
        let placeholder = ClipboardBlocks.placeholder(copyID: id, index: index)
        var data = Data()
        do {
          try engine.editor.getResourceData(url: url, chunkSize: Self.readChunkSize) { chunk in
            budget -= chunk.count
            guard budget >= 0 else { return false }
            data.append(chunk)
            return true
          }
        } catch {
          readFailed = true
        }
        let mimeType = await (try? engine.editor.getMIMEType(url: url)) ?? ""
        resources[index] = (placeholder, .init(mimeType: mimeType, data: data))
        return URL(string: placeholder) ?? url
      }
    } catch {
      // Only this editor can paste a copy whose save failed. It keeps the session copy for that.
      portable = nil
    }
    // A copy above the budget, or with a resource that could not be read, only names itself, so only this editor
    // pastes it.
    let carried = budget >= 0 && !readFailed ? portable : nil
    let html = ClipboardBlocks.html(
      id: id,
      blocks: carried ?? "",
      resources: carried == nil ? [] : resources.keys.sorted().compactMap { resources[$0] },
      textHTML: textHTML,
    )
    var item: [String: Any] = [UTType.html.identifier: html]
    if !text.isEmpty {
      item[UTType.utf8PlainText.identifier] = text
    }
    pasteboard.setItems([item])
  }

  /// Pastes what the clipboard holds, in this order, as the web editor does: CE.SDK blocks, then media files and
  /// images, then SVG markup, then formatted text and plain text as a new text block.
  func paste() {
    guard let engine, editMode != .text, let page = try? engine.scene.getCurrentPage() else { return }
    let content = ClipboardContent(pasteboard)
    Task {
      do {
        guard try await pasteBlocks(engine: engine, page: page, content: content) == false,
              try await pasteMedia(engine: engine, page: page, content: content) == false,
              try await pasteText(engine: engine, page: page, content: content) == false else { return }
      } catch {
        handleError(error)
      }
    }
  }

  /// Whether an item of these types is a file. Text that another app offers is no file, so the canvas refuses a drop
  /// of only text, as the web canvas does.
  nonisolated static func isFile(_ types: [UTType]) -> Bool {
    types.contains { MediaKind($0) != nil } || !types.contains { type in textTypes.contains { type.conforms(to: $0) } }
  }

  /// Whether the canvas takes a drop of these items: one of them is a file, nothing covers the canvas, and the page
  /// allows `editor/add`, as for a paste. Reads only the types, so no file loads.
  func canDrop(_ providers: [NSItemProvider]) -> Bool {
    guard let engine, editMode != .text, !sheet.isPresented, !isPreviewMode, !error.isPresented,
          let page = try? engine.scene.getCurrentPage(),
          (try? engine.block.isAllowedByScope(page, key: "editor/add")) == true else { return false }
    return providers.contains { Self.isFile($0.registeredTypeIdentifiers.compactMap(UTType.init)) }
  }

  /// Adds the files of a drop on the canvas, as a paste of them does. Returns whether the canvas takes the drop.
  @discardableResult
  func drop(_ providers: [NSItemProvider]) -> Bool {
    guard canDrop(providers), let engine, let page = try? engine.scene.getCurrentPage() else { return false }
    let content = ClipboardContent(providers: providers)
    Task {
      do {
        _ = try await pasteMedia(engine: engine, page: page, content: content)
      } catch {
        handleError(error)
      }
    }
    return true
  }

  // MARK: - Blocks

  private func pasteBlocks(engine: Engine, page: DesignBlockID, content: ClipboardContent) async throws -> Bool {
    guard let html = content.html, let payload = ClipboardBlocks.parse(html: html) else { return false }
    let fromThisEditor = payload.id == lastClipboardCopy?.id
    let blocks = fromThisEditor ? lastClipboardCopy?.blocks ?? "" : payload.blocks
    // A copy too large to carry, from another editor, pastes as its text.
    guard !blocks.isEmpty else { return false }
    let mayAdd = try fromThisEditor || engine.block.isAllowedByScope(page, key: "editor/add")
    guard mayAdd else { return false }

    let loaded = try await engine.block.load(from: blocks)
    if !fromThisEditor {
      try relocate(payload.resources, engine: engine)
    }
    for id in engine.block.findAllSelected() {
      try engine.block.setSelected(id, selected: false)
    }
    let managesPages = try engine.editor.getRole() == Self.creatorRole
    var pasteCount = 0
    if fromThisEditor {
      lastClipboardCopy?.pasteCount += 1
      pasteCount = lastClipboardCopy?.pasteCount ?? 0
    }
    for id in loaded {
      let isPage = try engine.block.getType(id) == DesignBlockType.page.rawValue
      // A copy from another editor passed no check of this editor's role.
      if isPage, !managesPages {
        try engine.block.destroy(id)
        continue
      }
      // A copied page cannot nest inside a page, so it goes into the parent of the current one.
      let parent = try isPage ? engine.block.getParent(page) : page
      guard let parent else { continue }
      try engine.block.appendChild(to: parent, child: id)
      if fromThisEditor, !isPage, try !engine.block.isTransformLocked(id) {
        try offset(id, by: Self.pasteOffset * Float(pasteCount), engine: engine)
      }
      try engine.block.setSelected(id, selected: true)
    }
    try engine.editor.addUndoStep()
    return true
  }

  private func offset(_ id: DesignBlockID, by distance: Float, engine: Engine) throws {
    try engine.block.setPositionXMode(id, mode: .absolute)
    try engine.block.setPositionX(id, value: engine.block.getPositionX(id) + distance)
    try engine.block.setPositionYMode(id, mode: .absolute)
    try engine.block.setPositionY(id, value: engine.block.getPositionY(id) - distance)
  }

  /// Points the pasted blocks at files with the bytes that the copy carried. A file URL is what an upload has, so a
  /// host's scene save handles it already.
  private func relocate(_ resources: [String: ClipboardBlocks.Resource], engine: Engine) throws {
    for (placeholder, resource) in resources {
      guard let placeholderURL = URL(string: placeholder) else { continue }
      // A resource that fails to write keeps its placeholder, so its block shows an error instead of failing the
      // paste.
      do {
        let fileExtension = UTType(mimeType: resource.mimeType)?.preferredFilenameExtension ?? ""
        let url = try FileManager.default.getUniqueCacheURL().appendingPathExtension(fileExtension)
        try resource.data.write(to: url)
        try engine.editor.relocateResource(currentURL: placeholderURL, relocatedURL: url)
      } catch {
        continue
      }
    }
  }

  // MARK: - Media

  enum MediaKind {
    case vector, image, video, audio

    init?(_ type: UTType) {
      if type.conforms(to: .svg) {
        self = .vector
      } else if type.conforms(to: .image) {
        self = .image
      } else if type.conforms(to: .movie) || type.conforms(to: .video) {
        self = .video
      } else if type.conforms(to: .audio) {
        self = .audio
      } else {
        return nil
      }
    }
  }

  struct PastedMedia {
    let kind: MediaKind
    let file: PastedFile
  }

  /// The type identifiers of text, which a paste of text handles.
  nonisolated static let textTypes: [UTType] = [.text, .url]

  /// The image types that every engine decodes, preferred over another representation of the same item, such as
  /// the HEIC that Photos offers first.
  nonisolated static let preferredImageTypes: [UTType] = [.png, .jpeg]

  private func pasteMedia(engine: Engine, page: DesignBlockID, content: ClipboardContent) async throws -> Bool {
    let media = content.media
    let hasUnsupportedFile = content.hasUnsupportedFile
    guard !media.isEmpty || hasUnsupportedFile else { return false }
    guard try engine.block.isAllowedByScope(page, key: "editor/add") else { return false }

    let sources = engine.asset.findAllSources()
    var unsupported = hasUnsupportedFile
    var failure: Swift.Error?
    var added = false
    for item in media {
      // The upload takes each type that the editor's own picker takes, so a type has no list to match.
      let sourceID = uploadSourceID(for: item.kind)
      guard item.kind == .vector || sources.contains(sourceID) else {
        unsupported = true
        continue
      }
      do {
        let url = try await item.file.url
        try await addMedia(url: url, kind: item.kind, sourceID: sourceID, engine: engine, page: page)
        added = true
      } catch {
        failure = error
      }
    }
    if let failure {
      handleError(failure)
    } else if unsupported, !added {
      // As on the web, a copy of several files shows the message only when none was added.
      let message = String(localized: .imgly.localized("ly_img_editor_dialog_paste_error_unsupported_type"))
      handleError(Error(errorDescription: message))
    }
    return true
  }

  private func addMedia(url: URL, kind: MediaKind, sourceID: String, engine: Engine, page: DesignBlockID) async throws {
    switch kind {
    case .vector:
      let svg = try String(contentsOf: url, encoding: .utf8)
      try placePastedBlocks(engine: engine, [engine.block.createFromSVG(svg)], parent: page)
    case .image: _ = try await uploadImage(to: sourceID) { url }
    case .video: _ = try await uploadVideo(to: sourceID) { url }
    case .audio: _ = try await uploadAudio(to: sourceID) { url }
    }
  }

  private func uploadSourceID(for kind: MediaKind) -> String {
    switch kind {
    case .image, .vector: imageUploadAssetSourceID
    case .video: videoUploadAssetSourceID
    case .audio: "ly.img.audio.upload"
    }
  }

  // MARK: - Text

  private func pasteText(engine: Engine, page: DesignBlockID, content: ClipboardContent) async throws -> Bool {
    let plain = content.string ?? ""
    let html = content.html ?? ""
    guard !html.isEmpty || !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
    guard try engine.block.isAllowedByScope(page, key: "editor/add") else { return false }
    // Adobe Illustrator copies its selection as SVG markup in plain text.
    if ClipboardSVG.isMarkup(plain), let vector = try? engine.block.createFromSVG(plain) {
      try placePastedBlocks(engine: engine, [vector], parent: page)
      return true
    }

    let typeface = html.isEmpty ? nil : await PastedTextTypeface.find(engine: engine, html: html)
    let text = try engine.block.create(.text)
    do {
      if !html.isEmpty {
        if let typeface {
          try engine.block.setTypeface(text, typeface: typeface)
        }
        do {
          try engine.block.replaceTextWithHTML(text, html: html)
        } catch let error as EngineError where error.catalogCode == .blockTextHtmlHasNoText {
          // A CE.SDK copy too large to carry holds no text, and so pastes nothing here.
          guard !plain.isEmpty else {
            try engine.block.destroy(text)
            return false
          }
          try engine.block.replaceText(text, text: plain)
        }
      } else {
        try engine.block.replaceText(text, text: plain)
      }
    } catch {
      try? engine.block.destroy(text)
      throw error
    }
    try engine.block.setWidthMode(text, mode: .auto)
    try engine.block.setHeightMode(text, mode: .auto)
    try engine.block.appendChild(to: page, child: text)
    // A long line wraps instead of running past the page.
    let maxWidth = try engine.block.getFrameWidth(page) * Self.maxWidthOfPage
    if try engine.block.getFrameWidth(text) > maxWidth {
      try engine.block.setWidthMode(text, mode: .absolute)
      try engine.block.setWidth(text, value: maxWidth)
    }
    // A shrunk font would be unreadable, so a long text runs past the page.
    try placePastedBlocks(engine: engine, [text], parent: page, shrinkToFit: false)
    return true
  }

  // MARK: - Placement

  /// Places content from outside CE.SDK on a page: appends it, shrinks it to fit unless `shrinkToFit` is `false`,
  /// centers it, selects it and adds one undo step. The blocks keep their layout relative to each other.
  private func placePastedBlocks(
    engine: Engine,
    _ ids: [DesignBlockID],
    parent: DesignBlockID,
    shrinkToFit: Bool = true,
  ) throws {
    guard !ids.isEmpty else { return }
    let block = engine.block
    for id in ids {
      try block.appendChild(to: parent, child: id)
    }
    let frames = try ids.map { id in
      try (id: id, x: block.getPositionX(id), y: block.getPositionY(id),
           width: block.getFrameWidth(id), height: block.getFrameHeight(id))
    }
    let minX = frames.map(\.x).min() ?? 0
    let minY = frames.map(\.y).min() ?? 0
    let width = (frames.map { $0.x + $0.width }.max() ?? 0) - minX
    let height = (frames.map { $0.y + $0.height }.max() ?? 0) - minY

    let parentWidth = try block.getFrameWidth(parent)
    let parentHeight = try block.getFrameHeight(parent)
    let factor = shrinkToFit ? min(1, parentWidth / width, parentHeight / height) : 1
    let left = (parentWidth - width * factor) / 2
    let top = (parentHeight - height * factor) / 2

    for id in block.findAllSelected() {
      try block.setSelected(id, selected: false)
    }
    for frame in frames {
      if factor < 1 {
        try block.scale(frame.id, to: factor)
      }
      try block.setPositionX(frame.id, value: left + (frame.x - minX) * factor)
      try block.setPositionY(frame.id, value: top + (frame.y - minY) * factor)
      try block.setSelected(frame.id, selected: true)
    }
    try engine.editor.addUndoStep()
  }
}
