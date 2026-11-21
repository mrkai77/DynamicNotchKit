//
//  IslandAnchorTests.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2026-11-21.
//

import AppKit
@testable import DynamicNotchKit
import Testing

@Suite("Island anchor")
struct IslandAnchorTests {
    private let frame = CGRect(x: 0, y: 0, width: 1512, height: 993)
    private let island = CGRect(x: 726.5, y: 953, width: 59, height: 32)

    @Test("Hardware island from this machine's cutout")
    func hardwareIsland() {
        let anchor = IslandAnchor.make(cutout: .island(island), screenFrame: frame, menubarHeight: 45)
        #expect(anchor == IslandAnchor(size: CGSize(width: 59, height: 32), topInset: 8, xOffset: 0, isHardware: true))
        #expect(anchor.compactGapWidth == 59)
    }

    @Test("Hardware island on a non-zero-origin screen")
    func hardwareIslandAtNonZeroOrigin() {
        let frame = CGRect(x: -1512, y: 200, width: 1512, height: 993)
        let island = CGRect(x: -785.5, y: 1153, width: 59, height: 32)
        let anchor = IslandAnchor.make(cutout: .island(island), screenFrame: frame, menubarHeight: 45)
        #expect(anchor == IslandAnchor(size: CGSize(width: 59, height: 32), topInset: 8, xOffset: 0, isHardware: true))
    }

    @Test("Off-centre hardware island keeps its horizontal offset")
    func offCentreHardwareIsland() {
        let island = CGRect(x: 736.5, y: 953, width: 59, height: 32)
        let anchor = IslandAnchor.make(cutout: .island(island), screenFrame: frame, menubarHeight: 45)
        #expect(anchor.xOffset == 10)
    }

    @Test("Virtual pill in a 24pt menu bar", arguments: [ScreenCutout.none, .notch(CGRect(x: 663, y: 961, width: 186, height: 32))])
    func virtualIn24ptMenuBar(cutout: ScreenCutout) {
        let anchor = IslandAnchor.make(cutout: cutout, screenFrame: frame, menubarHeight: 24)
        #expect(anchor == IslandAnchor(size: CGSize(width: 126, height: 18), topInset: 3, xOffset: 0, isHardware: false))
        #expect(anchor.compactGapWidth == 0)
    }

    @Test("Virtual pill in a 45pt menu bar")
    func virtualIn45ptMenuBar() {
        let anchor = IslandAnchor.make(cutout: .none, screenFrame: frame, menubarHeight: 45)
        #expect(anchor.size.height == 39)
        #expect(anchor.topInset == 3)
    }

    @Test("Virtual pill never has a negative height")
    func virtualWithZeroMenuBar() {
        let anchor = IslandAnchor.make(cutout: .none, screenFrame: frame, menubarHeight: 0)
        #expect(anchor.size.height == 0)
        #expect(anchor.topInset == 3)
        #expect(!anchor.isHardware)
    }
}
