//
//  Color.swift
//  BillsApp
//
//  Created by Elen Hayot on 02/02/2026.
//

import Foundation
import Combine
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Extensions for Cross-Platform Compatibility
extension Color {
    static var systemGroupedBackground: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    static var cardBackground: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    static var textFieldBackground: Color {
        #if os(iOS)
        Color(UIColor.systemGray6)
        #else
        Color(NSColor.textBackgroundColor)
        #endif
    }
}
