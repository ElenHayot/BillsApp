//
//  CategoriesListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var isLoading = false
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
    
    func deleteCategory(category: Category) async {
        do {
            try await APIClient.shared.deleteCategory(
                categoryId: category.id
            )
            // Remove from local list
            categories.removeAll { $0.id == category.id }
        } catch {
            errorMessage = "Failed to delete category: \(error.localizedDescription)"
        }
    }
}
