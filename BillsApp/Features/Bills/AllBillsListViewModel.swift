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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var categories: [Category] = []
    
    func loadBills(token: String, year: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            bills = try await BillsService.shared.fetchAllBills(token: token, year: year)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func categoryColor(for categoryId: Int) -> String {
        categories.first(where: { $0.id == categoryId })?.color ?? "#999999"
    }
}

// ✅ Extension de Bill pour inclure la couleur de catégorie
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
