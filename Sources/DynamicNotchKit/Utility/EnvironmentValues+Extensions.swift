//
//  EnvironmentValues+Extensions.swift
//  DynamicNotchKit
//
//  Created by Kai Azim on 2025-03-26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var notchSection: DynamicNotchSection = .expanded
    @Entry var compactLabelPadding: CGFloat = 4
}

enum DynamicNotchSection {
    case expanded
    case compactLeading
    case compactTrailing
}
