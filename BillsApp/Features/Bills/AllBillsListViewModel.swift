//
//  AllBillsListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class AllBillsListViewModel: ObservableObject {
    
    @Published var bills: [BillWithCategory] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isDeleting: Bool = false

    func loadBills(
        year: Int,
        categoryId: Int? = nil,
        title: String? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load categories
            categories = try await APIClient.shared.fetchCategories()
            
            // Load bills with filters
            let plainBills = try await APIClient.shared.fetchAllBills(
                year: year,
                categoryId: categoryId,
                title: title,
                minAmount: minAmount,
                maxAmount: maxAmount
            )
            
            // Associate bill <-> category
            bills = plainBills.map { bill in
                let categoryColor = categories.first(where: { $0.id == bill.bill.categoryId })?.color
                return BillWithCategory(bill: bill.bill, categoryColor: categoryColor)
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }
        
        isLoading = false
    }
    
    func deleteBill(
        billId: Int
    ) async throws {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIClient.shared.deleteBill(
                billId: billId
            )
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
    }
    
    // Return the category color
    func categoryColor(for categoryId: Int) -> String {
        categories.first(where: { $0.id == categoryId })?.color ?? "#999999"
    }
}

// Bill extension to include category color
struct BillWithCategory: Identifiable {
    let bill: Bill
    let categoryColor: String?
    
    var id: Int { bill.id }
    var title: String { bill.title }
    var amount: Decimal { bill.amount }
    var date: Date { bill.date }
    var categoryId: Int { bill.categoryId }
    var comment: String? { bill.comment }
    var createdAt: Date { bill.createdAt }
    var updatedAt: Date { bill.updatedAt }
    var amountFormatted: String { bill.amountFormatted }
    var dateFormatted: String { bill.dateFormatted }
}
