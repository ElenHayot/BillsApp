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
    @Published var providers: [Provider] = []
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
    
    func loadProviders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            providers = try await APIClient.shared.fetchProviders()
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
        providerId: Int?,
        providerName: String,
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
                providerId: providerId,
                providerName: providerName,
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
        providerId: Int?,
        providerName: String,
        comment: String
    ) async -> Bill? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let bill = try await APIClient.shared.updateBill(
                billId: billId,
                title: title,
                amount: amount,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName,
                comment: comment
            )
            return bill
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
