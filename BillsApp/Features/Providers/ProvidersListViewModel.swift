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
    @Published var errorMessage: String?

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
    
    func deleteProvider(providerId: Int) async {
        do {
            try await APIClient.shared.deleteProvider(
                providerId: providerId
            )
            // Remove from local list
            providers.removeAll { $0.id == providerId }
        } catch {
            errorMessage = "Erreur lors de la suppression du fournisseur : \(error.localizedDescription)"
        }
    }
}


