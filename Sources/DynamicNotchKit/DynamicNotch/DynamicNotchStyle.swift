//
//  DynamicNotchStyle.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2025-04-18.
//

import SwiftUI

/// The style of a DynamicNotch.
///
/// The style determines how the notch appears on the screen.
/// It is generally recommended to use the ``auto`` style, which will automatically choose the best style based on the screen.
/// However, you can also use the ``notch`` or ``island`` styles to force the notch to appear in a specific way.
///
/// ## Complex Usage
///
/// Custom border radii can easily complement a rounded user interface.
/// Remember this formula instead of eyeballing the corner radius, if you haven't already!
/// ```
/// Outer Radius = Inner Radius + Padding
/// ```
/// In order to set a custom corner radius, use the following cases:
/// - ``notch(topCornerRadius:bottomCornerRadius:)``
/// - ``island(cornerRadius:)``
///
public enum DynamicNotchStyle: Sendable {
    /// Notch-style, meant to be used on screens with a notch
    ///
    /// Note that `topCornerRadius` and `bottomCornerRadius` are only use when the notch is in the expanded state.
    case notch(
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat
    )

    /// Dynamic Island-style, meant to be used on screens with a Dynamic Island, or on screens without any cutout.
    ///
    /// On screens with a Dynamic Island, the window grows out of the physical island.
    /// On screens without a cutout, a virtual island is shown inside the menu bar.
    ///
    /// Note that `cornerRadius` is only used when the island is in the expanded state.
    case island(
        cornerRadius: CGFloat
    )

    /// Automatically choose the style based on the screen
    case auto

    /// A preset notch style, made to look good in most cases.
    public static let notch: DynamicNotchStyle = .notch(topCornerRadius: 15, bottomCornerRadius: 20)

    /// A preset island style, made to look good in most cases.
    public static let island: DynamicNotchStyle = .island(cornerRadius: 20)

    /// The floating style has been replaced by the island style.
    @available(*, deprecated, renamed: "island")
    public static var floating: DynamicNotchStyle { .island }

    /// The floating style has been replaced by the island style.
    @available(*, deprecated, renamed: "island(cornerRadius:)")
    public static func floating(cornerRadius: CGFloat) -> DynamicNotchStyle {
        .island(cornerRadius: cornerRadius)
    }

    var isNotch: Bool {
        if case .notch = self {
            true
        } else {
            false
        }
    }

    var openingAnimation: Animation {
        .bouncy(duration: 0.4)
    }

    var closingAnimation: Animation {
        .smooth(duration: 0.4)
    }

    var conversionAnimation: Animation {
        .snappy(duration: 0.4)
    }
}

extension DynamicNotchStyle: Equatable {
    public static func == (lhs: DynamicNotchStyle, rhs: DynamicNotchStyle) -> Bool {
        switch (lhs, rhs) {
        case let (.notch(lhsTop, lhsBottom), .notch(rhsTop, rhsBottom)):
            lhsTop == rhsTop && lhsBottom == rhsBottom
        case let (.island(lhsRadius), .island(rhsRadius)):
            lhsRadius == rhsRadius
        case (.auto, .auto):
            true
        default:
            false
        }
    }
}
