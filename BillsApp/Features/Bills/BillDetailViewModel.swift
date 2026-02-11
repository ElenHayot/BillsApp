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
    @Published var successMessage: String?

    func deleteBill(
        billId: Int
    ) async throws -> Bool {

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIClient.shared.deleteBill(
                billId: billId
            )
            successMessage = "Facture supprimée avec succès !"
            return true
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isDeleting = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isDeleting = false
            throw error
        }
    }
}
