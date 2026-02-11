//
//  ProvidersListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ProvidersListViewModel: ObservableObject {

    @Published var providers: [Provider] = []
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func loadProviders() async {

        isLoading = true
        errorMessage = nil

        do {
            providers = try await APIClient.shared.fetchProviders()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }

        isLoading = false
    }
    
    func deleteProvider(providerId: Int) async throws {
        isDeleting = true
        do {
            try await APIClient.shared.deleteProvider(
                providerId: providerId
            )
            // Remove from local list
            providers.removeAll { $0.id == providerId }
            
            successMessage = "Fournisseur supprimé avec succès !"
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isDeleting = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isDeleting = false
            throw error
        }
        
        isDeleting = false
    }
}


