//
//  UnifiedBillsListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 13/02/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class UnifiedBillsListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var bills: [BillWithCategory] = []
    @Published var categories: [Category] = [] // Only used for "all-bills" view
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isDeleting: Bool = false

    // MARK: - Mode "all-bills"
    
    /// Load all bills for a given year
    func loadAllBills(
        year: Int,
        categoryId: Int? = nil,
        title: String? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load categorys (used to display category color)
            categories = try await APIClient.shared.fetchCategories()
            
            let plainBills = try await APIClient.shared.fetchAllBills(
                year: year,
                categoryId: categoryId,
                title: title,
                minAmount: minAmount,
                maxAmount: maxAmount
            )
            
            // Associate each bill to its category color
            bills = plainBills.map { bill in
                let categoryColor = categories.first(where: { $0.id == bill.bill.categoryId })?.color
                return BillWithCategory(bill: bill.bill, categoryColor: categoryColor)
            }
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
        }
        
        isLoading = false
    }
    
    // MARK: - Mode "bill-by-category"
    
    /// Load all bills for a given year and a given categoryId
    func loadCategoryBills(
        categoryId: Int,
        year: Int
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let plainBills = try await APIClient.shared.fetchBillsGroupedByCategory(
                categoryId: categoryId,
                year: year
            )
            
            // Convert into BillWithCategory
            let categoryColor = try await APIClient.shared.fetchCategories()
                .first(where: { $0.id == categoryId })?.color ?? "#999999"
            
            bills = plainBills.map { bill in
                BillWithCategory(bill: bill, categoryColor: categoryColor)
            }
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
        }
        
        isLoading = false
    }
    
    // MARK: - Common operations
    
    /// Delete a bill
    func deleteBill(billId: Int) async throws {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIClient.shared.deleteBill(billId: billId)
            
            // Remove the bill from the list
            bills.removeAll { $0.id == billId }
            successMessage = "Facture supprimée avec succès !"
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            throw error
        }
    }
    
    // MARK: - Helpers
    
    /// Return a category color
    func categoryColor(for categoryId: Int) -> String {
        categories.first(where: { $0.id == categoryId })?.color ?? "#999999"
    }
}

// MARK: - BillWithCategory

/// Bill extension to include its category color
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
