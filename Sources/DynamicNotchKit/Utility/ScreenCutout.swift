//
//  ScreenCutout.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2026-11-21.
//

import AppKit

enum ScreenCutout: Equatable {
    case island(CGRect)

    case notch(CGRect)

    case none

    static let tolerance: CGFloat = 1

    static func classify(
        screenFrame: CGRect,
        subpathBounds: [CGRect]?,
        fallbackNotchFrame: CGRect?
    ) -> ScreenCutout {
        let fallback: ScreenCutout = fallbackNotchFrame.map { .notch($0) } ?? .none

        guard let subpathBounds else {
            return fallback
        }

        let localBounds = CGRect(origin: .zero, size: screenFrame.size)
        let cutouts = subpathBounds.filter { !$0.isApproximatelyEqual(to: localBounds, tolerance: tolerance) }

        if let island = cutouts.first(where: { !$0.isEmpty && $0.minY > localBounds.midY && $0.maxY < localBounds.maxY - tolerance }) {
            return .island(island.offsetBy(dx: screenFrame.minX, dy: screenFrame.minY))
        }

        if let notch = cutouts.first(where: { abs($0.maxY - localBounds.maxY) <= tolerance }) {
            return .notch(notch.offsetBy(dx: screenFrame.minX, dy: screenFrame.minY))
        }

        return fallback
    }

    static func closedSubpathBounds(of path: NSBezierPath) -> [CGRect] {
        var result: [CGRect] = []
        var current: NSBezierPath?
        var subpathStart: NSPoint = .zero
        var points = [NSPoint](repeating: .zero, count: 3)

        for index in 0 ..< path.elementCount {
            let element = points.withUnsafeMutableBufferPointer { buffer in
                path.element(at: index, associatedPoints: buffer.baseAddress)
            }

            switch element.rawValue {
            case NSBezierPath.ElementType.moveTo.rawValue:
                current = NSBezierPath()
                current?.move(to: points[0])
                subpathStart = points[0]
            case NSBezierPath.ElementType.lineTo.rawValue:
                ensureSubpath(&current, start: subpathStart)
                current?.line(to: points[0])
            case 2: // cubicCurveTo
                ensureSubpath(&current, start: subpathStart)
                current?.curve(to: points[2], controlPoint1: points[0], controlPoint2: points[1])
            case 4: // quadraticCurveTo (macOS 14+)
                ensureSubpath(&current, start: subpathStart)
                if #available(macOS 14.0, *) {
                    current?.curve(to: points[1], controlPoint: points[0])
                } else {
                    current?.line(to: points[1])
                }
            case NSBezierPath.ElementType.closePath.rawValue:
                if let subpath = current, !subpath.isEmpty {
                    subpath.close()
                    result.append(subpath.bounds)
                }
                current = nil
            default:
                break
            }
        }

        return result
    }

    static func normalizedNotchFrame(_ rect: CGRect, screenFrame: CGRect) -> CGRect? {
        guard !rect.isEmpty, !rect.isNull, !rect.isInfinite else {
            return nil
        }

        if screenFrame.contains(rect) {
            return rect
        }

        let localBounds = CGRect(origin: .zero, size: screenFrame.size)
        if localBounds.contains(rect) {
            return rect.offsetBy(dx: screenFrame.minX, dy: screenFrame.minY)
        }

        return nil
    }

    private static func ensureSubpath(_ subpath: inout NSBezierPath?, start: NSPoint) {
        guard subpath == nil else { return }
        let path = NSBezierPath()
        path.move(to: start)
        subpath = path
    }
}

// MARK: - CGRect + Helpers

private extension CGRect {
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance &&
            abs(minY - other.minY) <= tolerance &&
            abs(maxX - other.maxX) <= tolerance &&
            abs(maxY - other.maxY) <= tolerance
    }
}

// MARK: - NSScreen + Private API

// Every private AppKit call is guarded with `responds(to:)` and returns nil when unavailable.
extension NSScreen {
    var privateBezelPath: NSBezierPath? {
        let selector = NSSelectorFromString("bezelPath")
        guard responds(to: selector) else { return nil }
        return perform(selector)?.takeUnretainedValue() as? NSBezierPath
    }

    var privateNotchFrame: NSRect? {
        let selector = NSSelectorFromString("_notchFrame")
        guard responds(to: selector) else { return nil }

        typealias Function = @convention(c) (AnyObject, Selector) -> NSRect
        let function = unsafeBitCast(method(for: selector), to: Function.self)
        let rect = function(self, selector)

        return ScreenCutout.normalizedNotchFrame(rect, screenFrame: frame)
    }

    var privateRestingMenuBarHeight: CGFloat? {
        let selector = NSSelectorFromString("_restingMenuBarHeight")
        guard responds(to: selector) else { return nil }

        typealias Function = @convention(c) (AnyObject, Selector) -> Double
        let function = unsafeBitCast(method(for: selector), to: Function.self)
        let height = CGFloat(function(self, selector))

        return height > 0 ? height : nil
    }

    var cutout: ScreenCutout {
        // Falls back to the public notch frame, so `.auto` doesn't depend on `_notchFrame` behaving on external displays
        ScreenCutout.classify(
            screenFrame: frame,
            subpathBounds: privateBezelPath.map { ScreenCutout.closedSubpathBounds(of: $0) },
            fallbackNotchFrame: publicNotchFrame
        )
    }
}
