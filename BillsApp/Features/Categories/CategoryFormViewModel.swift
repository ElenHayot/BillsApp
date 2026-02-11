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
    @Published var successMessage: String?
    
    func createCategory(
        name: String,
        color: String
    ) async throws -> Category? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let category = try await APIClient.shared.createCategory(
                name: name,
                color: color
            )
            
            successMessage = "Catégorie créée avec succès !"
            return category
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isSaving = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isSaving = false
            throw error
        }
    }
    
    func updateCategory(
        categoryId: Int,
        name: String,
        color: String
    ) async throws -> Category? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let category = try await APIClient.shared.updateCategory(
                categoryId: categoryId,
                name: name,
                color: color
            )
            
            successMessage = "Catégorie mise à jour avec succès !"
            return category
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isSaving = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isSaving = false
            throw error
        }
    }
}
