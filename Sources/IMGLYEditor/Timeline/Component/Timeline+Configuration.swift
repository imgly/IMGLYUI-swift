import SwiftUI

public extension Timeline {
  /// How the timeline's height is determined, expressed in track rows.
  ///
  /// Every case counts *overlay* tracks. The background track is always shown and is never counted,
  /// and the caption lane is a lane of its own rather than an overlay track.
  enum HeightMode {
    /// The timeline auto-resizes to fit its tracks, growing to at most `maximumTracks` tracks tall.
    /// This is the default.
    ///
    /// A caption lane is added on top of `maximumTracks`, so a scene with captions is one row
    /// taller than one without. The lane appears with the first caption clip, not with the caption
    /// track, so an empty caption track adds nothing. Use ``fixed(tracks:)`` when the height must
    /// not move.
    case dynamic(maximumTracks: Int = 3)
    /// The timeline uses a fixed height sized to show exactly `tracks` tracks, without
    /// auto-resizing.
    ///
    /// `tracks` counts overlay tracks above the background track, so `0` still shows the
    /// background track. Negative values are clamped to `0`.
    ///
    /// Fixed means fixed: unlike ``dynamic(maximumTracks:)``, a caption lane does not add a row.
    case fixed(tracks: Int)
  }

  /// Customizes the timeline's add-content entry points, header, and height.
  ///
  /// Pass a configuration to ``Timeline/init(context:configuration:isExpanded:)``.
  ///
  /// The defaults render the tracks alone: no header, and no "Add Clip" or "Add Audio" button.
  /// Declare each surface you need.
  ///
  /// The `configure` closure runs each time a configuration is created, and the bottom panel
  /// creates its content on every render. Keep the closure cheap, or build the configuration once
  /// and capture it.
  struct Configuration {
    /// The "Add Clip" button, or `nil` when it is removed.
    let addClip: (any Timeline.Item)?
    /// The "Add Audio" button, or `nil` when it is removed.
    let addAudio: (any Timeline.Item)?
    /// The timeline's height and dynamic resizing.
    let height: Timeline.Height
    /// The header bar shown above the timeline.
    let header: Timeline.Header
    /// Modifications applied to ``Builder/header(_:)`` in order.
    let headerModifications: [Timeline.Modifications]

    /// Creates timeline configuration.
    /// - Parameter configure: A closure that configures the timeline.
    public init(_ configure: (inout Builder) -> Void = { _ in }) {
      var builder = Builder()
      configure(&builder)
      addClip = builder.addClip
      addAudio = builder.addAudio
      height = builder.height
      header = builder.header
      headerModifications = builder.modifications
    }

    /// Builder for timeline configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The "Add Clip" button. Use ``Timeline/Buttons/addClip(options:title:icon:isEnabled:)`` to configure its
      /// options, a ``Timeline/Custom`` to replace it entirely, or `nil` to remove it.
      ///
      /// A replacement sits in the background lane and is sized to one track row, like the track
      /// beside it. The timeline reserves its height by row count and never measures this button,
      /// so a taller one would overflow the lane.
      public var addClip: (any Timeline.Item)?

      /// The "Add Audio" button. Use ``Timeline/Buttons/addAudio(options:title:icon:isEnabled:)`` to configure its
      /// options, a ``Timeline/Custom`` to replace it entirely, or `nil` to remove it.
      ///
      /// A replacement is sized to one track row, as ``addClip`` is.
      public var addAudio: (any Timeline.Item)?

      /// The timeline's height, expressed in track rows.
      ///
      /// Resolved per render, so the height can depend on the ``Timeline/ItemContext`` — the editor
      /// state, or the vertical size class.
      public var height: Timeline.Height = { _ in .dynamic() }

      /// The header bar shown above the timeline. Set via ``header(_:)``.
      var header: Timeline.Header = { _ in [] }

      /// The header modifications.
      var modifications: [Timeline.Modifications] = []

      /// Sets the header bar shown above the timeline using a result builder. Use
      /// ``Timeline/Buttons`` factories grouped by ``Timeline/ItemPlacement``, or provide your own
      /// ``Timeline/Custom`` items.
      ///
      /// Replacing the header freezes it against today's built-in items. Prefer ``modifyHeader(_:)``
      /// when you only want to adjust one. An empty builder removes the header, and the player bar
      /// collapses with it.
      ///
      /// Evaluated per render, so the header can depend on the ``Timeline/ItemContext``.
      /// - Parameter newHeader: A builder closure to evaluate the header groups.
      public mutating func header(@Timeline.HeaderBuilder _ newHeader: @escaping Timeline.Header) {
        header = newHeader
      }

      /// Adds a modification to the header. Modifications accumulate in order and are applied on
      /// top of ``header(_:)``, so the built-in items can be adjusted without restating them.
      ///
      /// Use `addFirst(placement:)` or `addLast(placement:)` on the ``Timeline/Modifier`` to place
      /// an item without naming a neighbour; the id-anchored operations throw when the item they
      /// name is gone.
      ///
      /// This is how an integration keeps up with future built-in header items instead of freezing
      /// against today's set.
      /// - Parameter modification: The modification to add.
      public mutating func modifyHeader(_ modification: @escaping Timeline.Modifications) {
        modifications.append(modification)
      }
    }
  }
}
