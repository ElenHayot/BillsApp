//
//  AppKeyboardType.swift
//  BillsApp
//
//  Created by Elen Hayot on 02/02/2026.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum AppKeyboardType {
    case `default`
    case emailAddress
    case decimalPad
    case numberPad
    case URL
    case phonePad
    
    #if os(iOS)
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        case .numberPad: return .numberPad
        case .URL: return .URL
        case .phonePad: return .phonePad
        }
    }
    #endif
}
