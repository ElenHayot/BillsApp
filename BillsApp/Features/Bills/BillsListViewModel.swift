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
    @Published var errorMessage: String?

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
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func deleteBill(billId: Int) async {
        do {
            try await APIClient.shared.deleteBill(
                billId: billId
            )
            // Remove from local list
            bills.removeAll { $0.id == billId }
        } catch {
            errorMessage = "Erreur lors de la suppression de la facture: \(error.localizedDescription)"
        }
    }
}


