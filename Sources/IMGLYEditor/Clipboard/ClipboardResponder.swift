import SwiftUI
import UIKit

/// The responder for Cut, Copy and Paste on the canvas: the keyboard shortcuts on iPad and Mac, and the edit menu that
/// a long press on the canvas opens. A paste reads the clipboard inside these system commands, where iOS shows no
/// "Allow Paste" prompt for content from another app, as it does for a read from a custom button.
struct ClipboardResponder: UIViewRepresentable {
  let interactor: Interactor
  /// Whether the canvas takes the commands. A text field of a sheet or the engine's text editing takes them otherwise.
  let isActive: Bool
  /// Set to a point in the canvas to open the edit menu there.
  @Binding var menuLocation: CGPoint?

  func makeUIView(context _: Context) -> ResponderView {
    ResponderView(interactor: interactor)
  }

  func updateUIView(_ view: ResponderView, context _: Context) {
    view.interactor = interactor
    view.isActive = isActive
    if let menuLocation {
      DispatchQueue.main.async {
        self.menuLocation = nil
        view.presentMenu(at: menuLocation)
      }
    }
  }

  final class ResponderView: UIView, UIEditMenuInteractionDelegate {
    weak var interactor: Interactor?
    private lazy var editMenu = UIEditMenuInteraction(delegate: self)

    /// An inactive view gives up first responder and takes it back once it is active again. A view that keeps it
    /// while a sheet is open sends the main thread into an input-view reload loop when a menu in the sheet opens.
    var isActive = false {
      didSet {
        if isActive, !oldValue {
          becomeFirstResponder()
        } else if !isActive, isFirstResponder {
          resignFirstResponder()
        }
      }
    }

    init(interactor: Interactor) {
      self.interactor = interactor
      super.init(frame: .zero)
      backgroundColor = .clear
      addInteraction(editMenu)
      // A text field outside the editor's sheets, such as one of the host, takes the keys while it edits.
      NotificationCenter.default.addObserver(
        self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil,
      )
    }

    @objc private func keyboardDidHide() {
      if isActive, window != nil, !isFirstResponder {
        becomeFirstResponder()
      }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // The canvas below takes every touch.
    override func hitTest(_: CGPoint, with _: UIEvent?) -> UIView? {
      nil
    }

    // An empty input view, otherwise iOS shows the software keyboard for this responder when a menu opens.
    private let noKeyboard = UIView()

    override var inputView: UIView? {
      noKeyboard
    }

    override var canBecomeFirstResponder: Bool {
      isActive
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      if window != nil, isActive {
        becomeFirstResponder()
      }
    }

    func presentMenu(at point: CGPoint) {
      guard isActive, becomeFirstResponder() else { return }
      editMenu.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point))
    }

    override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
      guard isActive, let interactor else { return false }
      switch action {
      case #selector(copy(_:)): return interactor.canCopySelection
      case #selector(cut(_:)): return interactor.canCutSelection
      case #selector(paste(_:)): return interactor.canPaste
      default: return false
      }
    }

    override func copy(_: Any?) {
      interactor?.copySelection()
    }

    override func cut(_: Any?) {
      interactor?.copySelection(cut: true)
    }

    override func paste(_: Any?) {
      interactor?.paste()
    }
  }
}
