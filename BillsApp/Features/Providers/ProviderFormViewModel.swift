//
//  ProviderFormViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import Combine

@MainActor
final class ProviderFormViewModel: ObservableObject {
    
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    func createProvider(
        name: String
    ) async throws -> Provider? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let provider = try await APIClient.shared.createProvider(name: name)
            
            successMessage = "Fournisseur créé avec succès !"
            return provider
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
    
    func updateProvider(
        providerId: Int,
        name: String
    ) async throws -> Provider? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let provider = try await APIClient.shared.updateProvider(
                providerId: providerId,
                name: name
            )
            
            successMessage = "Fournisseur mis à jour avec succès !"
            return provider
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
