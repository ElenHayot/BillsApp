//
//  BillFormViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class BillFormViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await APIClient.shared.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createBill(
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        comment: String
    ) async -> Bill? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let bill = try await APIClient.shared.createBill(
                title: title,
                amount: amount,
                date: date,
                categoryId: categoryId,
                comment: comment
            )
            return bill
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func updateBill(
        billId: Int,
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        comment: String
    ) async -> Bill? {
        
        print("bill ID: \(billId), title: \(title), amount: \(amount), date: \(date), categoryId: \(categoryId), comment: \(comment)")
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let bill = try await APIClient.shared.updateBill(
                billId: billId,
                title: title,
                amount: amount,
                date: date,
                categoryId: categoryId,
                comment: comment
            )
            return bill
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
