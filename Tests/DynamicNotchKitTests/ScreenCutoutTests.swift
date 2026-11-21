//
//  ScreenCutoutTests.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2026-11-21.
//

import AppKit
@testable import DynamicNotchKit
import Testing

@Suite("Screen cutout")
struct ScreenCutoutTests {
    private let frame = CGRect(x: 0, y: 0, width: 1512, height: 993)
    private let outline = CGRect(x: 0, y: 0, width: 1512, height: 993)
    private let island = CGRect(x: 726.5, y: 953, width: 59, height: 32)
    private let fallbackNotch = CGRect(x: 663, y: 961, width: 186, height: 32)

    // MARK: - Classifier

    @Test("Island from this machine's bezel path")
    func islandAtZeroOrigin() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, island], fallbackNotchFrame: nil)
        #expect(result == .island(island))
    }

    @Test("Island is offset into global coordinates on a non-zero-origin screen")
    func islandAtNonZeroOrigin() {
        let frame = CGRect(x: -1512, y: 200, width: 1512, height: 993)
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, island], fallbackNotchFrame: nil)
        #expect(result == .island(CGRect(x: -785.5, y: 1153, width: 59, height: 32)))
    }

    @Test("Island wins even when a fallback notch frame exists")
    func islandIgnoresFallback() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, island], fallbackNotchFrame: fallbackNotch)
        #expect(result == .island(island))
    }

    @Test("Notch encoded in the outline uses the fallback notch frame")
    func notchInOutline() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline], fallbackNotchFrame: fallbackNotch)
        #expect(result == .notch(fallbackNotch))
    }

    @Test("Separate top-touching subpath is a notch")
    func separateNotchSubpath() {
        let notch = CGRect(x: 663, y: 961, width: 186, height: 32)
        let frame = CGRect(x: 100, y: -50, width: 1512, height: 993)
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, notch], fallbackNotchFrame: nil)
        #expect(result == .notch(CGRect(x: 763, y: 911, width: 186, height: 32)))
    }

    @Test("Outline within tolerance is dropped")
    func outlineTolerance() {
        let fuzzyOutline = CGRect(x: 0.5, y: -0.5, width: 1511.2, height: 993.8)
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [fuzzyOutline], fallbackNotchFrame: nil)
        #expect(result == .none)
    }

    @Test("Non-outline subpath in the lower half is not an island")
    func lowerHalfSubpathIgnored() {
        let lower = CGRect(x: 700, y: 10, width: 59, height: 32)
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, lower], fallbackNotchFrame: nil)
        #expect(result == .none)
    }

    @Test("Empty subpath is not an island")
    func emptySubpathIgnored() {
        let empty = CGRect(x: 700, y: 960, width: 0, height: 0)
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline, empty], fallbackNotchFrame: fallbackNotch)
        #expect(result == .notch(fallbackNotch))
    }

    @Test("No cutout")
    func noCutout() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: [outline], fallbackNotchFrame: nil)
        #expect(result == .none)
    }

    @Test("Missing bezel path with a fallback notch frame")
    func missingBezelWithFallback() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: nil, fallbackNotchFrame: fallbackNotch)
        #expect(result == .notch(fallbackNotch))
    }

    @Test("Missing bezel path without a fallback notch frame")
    func missingBezelWithoutFallback() {
        let result = ScreenCutout.classify(screenFrame: frame, subpathBounds: nil, fallbackNotchFrame: nil)
        #expect(result == .none)
    }

    // MARK: - Subpath splitting

    @Test("Closed subpaths are split with accurate bounds")
    func subpathSplitting() {
        let path = NSBezierPath(roundedRect: outline, xRadius: 10, yRadius: 10)
        path.append(NSBezierPath(roundedRect: island, xRadius: 16, yRadius: 16))

        let bounds = ScreenCutout.closedSubpathBounds(of: path)
        #expect(bounds.count == 2)
        #expect(bounds.first == outline)
        #expect(bounds.last == island)
    }

    @Test("Sub-pixel bezel geometry is kept as-is")
    func subpathSubPixelBoundsKept() {
        // Mirrors the real bezel path, whose island extrema sit at x = 726.4994, y = 953.0003.
        let fuzzyIsland = CGRect(x: 726.4994, y: 953.0003, width: 58.9996, height: 31.9993)
        let path = NSBezierPath(roundedRect: fuzzyIsland, xRadius: 16, yRadius: 16)

        let bounds = ScreenCutout.closedSubpathBounds(of: path)
        #expect(bounds.count == 1)
        #expect(abs(bounds[0].minX - fuzzyIsland.minX) < 0.0001)
        #expect(abs(bounds[0].minY - fuzzyIsland.minY) < 0.0001)
        #expect(abs(bounds[0].width - fuzzyIsland.width) < 0.0001)
        #expect(abs(bounds[0].height - fuzzyIsland.height) < 0.0001)
    }

    @Test("Unclosed subpaths are ignored")
    func unclosedSubpathIgnored() {
        let path = NSBezierPath(rect: outline)
        path.move(to: .init(x: 10, y: 10))
        path.line(to: .init(x: 20, y: 20))

        #expect(ScreenCutout.closedSubpathBounds(of: path) == [outline])
    }

    // MARK: - Public notch frame

    @Test("Public notch frame from this machine's auxiliary areas")
    func publicNotchFrameZeroOrigin() {
        let result = NSScreen.publicNotchFrame(
            screenFrame: frame,
            topLeftArea: CGRect(x: 0, y: 953, width: 726.5, height: 40),
            topRightArea: CGRect(x: 785.5, y: 953, width: 726.5, height: 40),
            topInset: 40
        )
        #expect(result == CGRect(x: 726.5, y: 953, width: 59, height: 40))
    }

    @Test("Public notch frame is offset on a non-zero-origin screen")
    func publicNotchFrameNonZeroOrigin() {
        let result = NSScreen.publicNotchFrame(
            screenFrame: CGRect(x: -1512, y: 200, width: 1512, height: 993),
            topLeftArea: CGRect(x: -1512, y: 1153, width: 726.5, height: 40),
            topRightArea: CGRect(x: -726.5, y: 1153, width: 726.5, height: 40),
            topInset: 40
        )
        #expect(result == CGRect(x: -785.5, y: 1153, width: 59, height: 40))
    }

    @Test("Public notch frame is nil without both auxiliary areas")
    func publicNotchFrameMissingArea() {
        let area = CGRect(x: 0, y: 953, width: 726.5, height: 40)
        #expect(NSScreen.publicNotchFrame(screenFrame: frame, topLeftArea: nil, topRightArea: area, topInset: 40) == nil)
        #expect(NSScreen.publicNotchFrame(screenFrame: frame, topLeftArea: area, topRightArea: nil, topInset: 40) == nil)
        #expect(NSScreen.publicNotchFrame(screenFrame: frame, topLeftArea: nil, topRightArea: nil, topInset: 0) == nil)
    }

    // MARK: - Notch frame normalisation

    @Test("Global notch frame passes through")
    func normalizeGlobal() {
        let frame = CGRect(x: -1512, y: 200, width: 1512, height: 993)
        let rect = CGRect(x: -785.5, y: 1153, width: 59, height: 40)
        #expect(ScreenCutout.normalizedNotchFrame(rect, screenFrame: frame) == rect)
    }

    @Test("Local notch frame is offset by a non-zero screen origin")
    func normalizeLocal() {
        let frame = CGRect(x: 1512, y: 200, width: 1512, height: 993)
        let rect = CGRect(x: 726.5, y: 953, width: 59, height: 40)
        #expect(ScreenCutout.normalizedNotchFrame(rect, screenFrame: frame) == CGRect(x: 2238.5, y: 1153, width: 59, height: 40))
    }

    @Test("Empty notch frame is nil")
    func normalizeEmpty() {
        #expect(ScreenCutout.normalizedNotchFrame(.zero, screenFrame: frame) == nil)
        #expect(ScreenCutout.normalizedNotchFrame(CGRect(x: 700, y: 953, width: 0, height: 40), screenFrame: frame) == nil)
    }

    @Test("Notch frame outside the screen is nil")
    func normalizeOutside() {
        let frame = CGRect(x: 1512, y: 200, width: 1512, height: 993)
        let rect = CGRect(x: 5000, y: 5000, width: 59, height: 40)
        #expect(ScreenCutout.normalizedNotchFrame(rect, screenFrame: frame) == nil)
    }

    // MARK: - Effective menu bar height

    @Test("Visible menu bar height wins")
    func effectiveMenubarVisible() {
        #expect(NSScreen.effectiveMenubarHeight(visible: 33, resting: 40, thickness: 24) == 33)
    }

    @Test("Hidden menu bar falls back to the resting height")
    func effectiveMenubarResting() {
        #expect(NSScreen.effectiveMenubarHeight(visible: 0, resting: 40, thickness: 24) == 40)
    }

    @Test("Hidden menu bar without a resting height falls back to the status bar thickness")
    func effectiveMenubarThickness() {
        #expect(NSScreen.effectiveMenubarHeight(visible: 0, resting: nil, thickness: 24) == 24)
    }
}
