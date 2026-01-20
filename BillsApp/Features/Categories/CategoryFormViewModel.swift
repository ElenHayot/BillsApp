//
//  CategoryFormViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class CategoryFormViewModel: ObservableObject {
    
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    func createCategory(
        name: String,
        color: String
    ) async -> Category? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let category = try await APIClient.shared.createCategory(
                name: name,
                color: color
            )
            return category
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func updateCategory(
        categoryName: String,
        name: String,
        color: String
    ) async -> Category? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let category = try await APIClient.shared.updateCategory(
                categoryName: categoryName,
                name: name,
                color: color
            )
            return category
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
