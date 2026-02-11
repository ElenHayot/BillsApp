//
//  BillsListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 04/01/2026.
//
import Foundation
import Combine
import SwiftUI

@MainActor
final class BillsListViewModel: ObservableObject {

    @Published var bills: [Bill] = []
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func loadBills(
        categoryId: Int,
        year: Int
    ) async {

        isLoading = true
        errorMessage = nil

        do {
            bills = try await APIClient.shared.fetchBillsGroupedByCategory(
                categoryId: categoryId,
                year: year
            )
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }

        isLoading = false
    }
    
    func deleteBill(billId: Int) async throws {
        isDeleting = true
        do {
            try await APIClient.shared.deleteBill(
                billId: billId
            )
            // Remove from local list
            bills.removeAll { $0.id == billId }
            successMessage = "Facture supprimée avec succès !"
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isDeleting = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isDeleting = false
            throw error
        }
        
        isDeleting = false
    }
}


