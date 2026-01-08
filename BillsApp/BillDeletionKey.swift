//
//  BillDeletionKey.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

private struct BillDeletionKey: EnvironmentKey {
    static let defaultValue: (Int) -> Void = { _ in }
}

extension EnvironmentValues {
    var onBillDeleted: (Int) -> Void {
        get { self[BillDeletionKey.self] }
        set { self[BillDeletionKey.self] = newValue }
    }
}   
