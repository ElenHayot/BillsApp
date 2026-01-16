//
//  BillDetailViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 05/01/2026.
//

import Foundation
import Combine

@MainActor
final class BillDetailViewModel: ObservableObject {

    @Published var isDeleting = false
    @Published var errorMessage: String?

    func deleteBill(
        billId: Int
    ) async -> Bool {

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIClient.shared.deleteBill(
                billId: billId
            )
            return true
        }
        catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
