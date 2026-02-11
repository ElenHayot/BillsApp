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
    @Published var successMessage: String?
    
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await APIClient.shared.fetchCategories()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }
        
        isLoading = false
    }
    
    func deleteCategory(category: Category) async throws {
        isLoading = true
        do {
            try await APIClient.shared.deleteCategory(
                categoryId: category.id
            )
            // Remove from local list
            categories.removeAll { $0.id == category.id }
            successMessage = "Catégorie supprimée avec succès !"
            isLoading = false
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
            throw error
        }
    }
}
