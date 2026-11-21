//
//  IslandView.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2026-11-21.
//

import SwiftUI

// MARK: - IslandAnchor

struct IslandAnchor: Equatable {
    var size: CGSize

    var topInset: CGFloat

    var xOffset: CGFloat

    var isHardware: Bool

    static let zero = IslandAnchor(size: .zero, topInset: 0, xOffset: 0, isHardware: false)

    static let virtualWidth: CGFloat = 126

    static let virtualVerticalInset: CGFloat = 3

    #if DEBUG
        nonisolated(unsafe) static var forcesVirtualAnchor = false
    #endif

    var compactGapWidth: CGFloat {
        isHardware ? size.width : 0
    }

    static func make(cutout: ScreenCutout, screenFrame: CGRect, menubarHeight: CGFloat) -> IslandAnchor {
        if case let .island(rect) = cutout {
            return IslandAnchor(
                size: rect.size,
                topInset: screenFrame.maxY - rect.maxY,
                xOffset: rect.midX - screenFrame.midX,
                isHardware: true
            )
        }

        return IslandAnchor(
            size: CGSize(
                width: virtualWidth,
                height: max(menubarHeight - (virtualVerticalInset * 2), 0)
            ),
            topInset: virtualVerticalInset,
            xOffset: 0,
            isHardware: false
        )
    }
}

// MARK: - IslandView

struct IslandView<Expanded, CompactLeading, CompactTrailing>: View where Expanded: View, CompactLeading: View, CompactTrailing: View {
    @ObservedObject private var dynamicNotch: DynamicNotch<Expanded, CompactLeading, CompactTrailing>
    @State private var compactLeadingWidth: CGFloat = 0
    @State private var compactTrailingWidth: CGFloat = 0
    private let safeAreaInset: CGFloat = 15

    init(dynamicNotch: DynamicNotch<Expanded, CompactLeading, CompactTrailing>) {
        self.dynamicNotch = dynamicNotch
    }

    private var anchor: IslandAnchor {
        dynamicNotch.islandAnchor
    }

    private var expandedCornerRadius: CGFloat {
        if case let .island(cornerRadius) = dynamicNotch.style {
            cornerRadius
        } else {
            20
        }
    }

    private var cornerRadius: CGFloat {
        switch dynamicNotch.state {
        case .expanded: expandedCornerRadius
        case .compact: anchor.size.height / 2
        case .hidden: hiddenSize.height / 2
        }
    }

    private var compactVerticalInset: CGFloat {
        max(0, ((anchor.size.height - 18) * 0.25).rounded())
    }

    private var compactLabelPadding: CGFloat {
        min(4, (anchor.size.height / 6).rounded())
    }

    private var compactOuterInset: CGFloat {
        max((anchor.size.height * 0.25).rounded(), 3)
    }

    private func compactInnerInset(otherSlotDisabled: Bool) -> CGFloat {
        if !anchor.isHardware, otherSlotDisabled {
            compactOuterInset
        } else {
            (anchor.size.height * 0.125).rounded()
        }
    }

    private var isCompactLeadingEmpty: Bool {
        dynamicNotch.disableCompactLeading || CompactLeading.self == EmptyView.self
    }

    private var isCompactTrailingEmpty: Bool {
        dynamicNotch.disableCompactTrailing || CompactTrailing.self == EmptyView.self
    }

    private var compactMinWidth: CGFloat {
        max(anchor.compactGapWidth, anchor.isHardware ? 0 : anchor.size.height)
    }

    private var isCollapsedVirtually: Bool {
        dynamicNotch.state == .hidden && !anchor.isHardware
    }

    private var hiddenSize: CGSize {
        if anchor.isHardware {
            // 0.5pt inside the physical island, so it doesn't fringe around it
            CGSize(width: max(anchor.size.width - 1, 0), height: max(anchor.size.height - 1, 0))
        } else {
            CGSize(width: anchor.size.width * 0.6, height: anchor.size.height * 0.6)
        }
    }

    private var xOffset: CGFloat {
        if dynamicNotch.state != .compact {
            0
        } else {
            compactXOffset
        }
    }

    private var compactXOffset: CGFloat {
        guard anchor.isHardware else { return 0 }
        return (compactTrailingWidth - compactLeadingWidth) / 2
    }

    var body: some View {
        islandContent()
            .background {
                Rectangle()
                    .foregroundStyle(.black)
                    .padding(-50) // The opening/closing animation can overshoot, so this makes sure that it's still black
            }
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .frame(
                        width: dynamicNotch.state != .hidden ? nil : hiddenSize.width,
                        height: dynamicNotch.state != .hidden ? nil : hiddenSize.height
                    )
                    .padding(.top, dynamicNotch.state != .hidden ? 0 : (anchor.size.height - hiddenSize.height) / 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .opacity(isCollapsedVirtually ? 0 : 1)
            .offset(x: anchor.xOffset + xOffset)
            .padding(.top, anchor.topInset)
            .animation(.smooth, value: [compactLeadingWidth, compactTrailingWidth])
    }

    private func islandContent() -> some View {
        ZStack {
            compactContent()
                .fixedSize()
                .offset(x: dynamicNotch.state == .compact ? 0 : compactXOffset)
                .frame(
                    width: dynamicNotch.state == .compact ? nil : anchor.size.width,
                    height: anchor.size.height
                )

            expandedContent()
                .fixedSize()
                .frame(
                    maxWidth: dynamicNotch.state == .expanded ? nil : 0,
                    maxHeight: dynamicNotch.state == .expanded ? nil : 0
                )
                .offset(x: dynamicNotch.state == .compact ? -compactXOffset : 0)
        }
        .fixedSize()
        .frame(
            minWidth: dynamicNotch.state == .compact ? compactMinWidth : anchor.size.width,
            minHeight: anchor.size.height
        )
        .onHover(perform: dynamicNotch.updateHoverState)
    }

    private func compactContent() -> some View {
        HStack(spacing: 0) {
            if dynamicNotch.state == .compact, !dynamicNotch.disableCompactLeading {
                dynamicNotch.compactLeadingContent
                    .environment(\.notchSection, .compactLeading)
                    .environment(\.compactLabelPadding, compactLabelPadding)
                    .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: compactOuterInset) }
                    .safeAreaInset(edge: .trailing, spacing: 0) {
                        Color.clear.frame(width: compactInnerInset(otherSlotDisabled: isCompactTrailingEmpty))
                    }
                    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: compactVerticalInset) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: compactVerticalInset) }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { compactLeadingWidth = $0 }
                    .transition(.blur(intensity: 10).combined(with: .scale(x: 0, anchor: .trailing)).combined(with: .opacity))
            }

            Spacer()
                .frame(width: anchor.compactGapWidth)

            if dynamicNotch.state == .compact, !dynamicNotch.disableCompactTrailing {
                dynamicNotch.compactTrailingContent
                    .environment(\.notchSection, .compactTrailing)
                    .environment(\.compactLabelPadding, compactLabelPadding)
                    .safeAreaInset(edge: .leading, spacing: 0) {
                        Color.clear.frame(width: compactInnerInset(otherSlotDisabled: isCompactLeadingEmpty))
                    }
                    .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: compactOuterInset) }
                    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: compactVerticalInset) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: compactVerticalInset) }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { compactTrailingWidth = $0 }
                    .transition(.blur(intensity: 10).combined(with: .scale(x: 0, anchor: .leading)).combined(with: .opacity))
            }
        }
        .frame(height: anchor.size.height)
        .onChange(of: dynamicNotch.disableCompactLeading) { _ in
            if dynamicNotch.disableCompactLeading {
                compactLeadingWidth = 0
            }
        }
        .onChange(of: dynamicNotch.disableCompactTrailing) { _ in
            if dynamicNotch.disableCompactTrailing {
                compactTrailingWidth = 0
            }
        }
    }

    private func expandedContent() -> some View {
        HStack(spacing: 0) {
            if dynamicNotch.state == .expanded {
                dynamicNotch.expandedContent
                    .transition(.blur(intensity: 10).combined(with: .scale(y: 0.6, anchor: .top)).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: max(anchor.size.height, safeAreaInset)) }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: safeAreaInset) }
        .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: safeAreaInset) }
        .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: safeAreaInset) }
        .frame(minWidth: anchor.size.width)
    }
}
