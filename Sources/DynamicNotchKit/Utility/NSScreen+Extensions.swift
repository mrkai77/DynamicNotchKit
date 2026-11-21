//
//  NSScreen+Extensions.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2024-04-06.
//

import SwiftUI

extension NSScreen {
    static var screenWithMouse: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

        return screenWithMouse
    }

    var hasNotch: Bool {
        notchFrame != nil
    }

    var notchSize: NSSize? {
        notchFrame?.size
    }

    var notchFrame: NSRect? {
        privateNotchFrame ?? publicNotchFrame
    }

    var publicNotchFrame: NSRect? {
        Self.publicNotchFrame(
            screenFrame: frame,
            topLeftArea: auxiliaryTopLeftArea,
            topRightArea: auxiliaryTopRightArea,
            topInset: safeAreaInsets.top
        )
    }

    nonisolated static func publicNotchFrame(
        screenFrame: NSRect,
        topLeftArea: NSRect?,
        topRightArea: NSRect?,
        topInset: CGFloat
    ) -> NSRect? {
        guard
            let topLeftNotchpadding: CGFloat = topLeftArea?.width,
            let topRightNotchpadding: CGFloat = topRightArea?.width
        else {
            return nil
        }

        let notchWidth = screenFrame.width - topLeftNotchpadding - topRightNotchpadding
        return .init(
            x: screenFrame.midX - (notchWidth / 2),
            y: screenFrame.maxY - topInset,
            width: notchWidth,
            height: topInset
        )
    }

    var menubarHeight: CGFloat {
        frame.maxY - visibleFrame.maxY
    }

    var effectiveMenubarHeight: CGFloat {
        Self.effectiveMenubarHeight(
            visible: menubarHeight,
            resting: privateRestingMenuBarHeight,
            thickness: NSStatusBar.system.thickness
        )
    }

    nonisolated static func effectiveMenubarHeight(visible: CGFloat, resting: CGFloat?, thickness: CGFloat) -> CGFloat {
        if visible > 0 {
            return visible
        }

        if let resting, resting > 0 {
            return resting
        }

        return thickness
    }

    var notchFrameWithMenubarAsBackup: NSRect {
        if let notchFrame {
            return notchFrame
        } else {
            let arbitraryNotchWidth: CGFloat = 300
            let arbitraryNotchHeight: CGFloat = effectiveMenubarHeight

            let arbitraryNotchFrame = NSRect(
                x: frame.midX - (arbitraryNotchWidth / 2),
                y: frame.maxY - arbitraryNotchHeight,
                width: arbitraryNotchWidth,
                height: arbitraryNotchHeight
            )

            return arbitraryNotchFrame
        }
    }
}
