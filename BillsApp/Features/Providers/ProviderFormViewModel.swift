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
    
    func createProvider(
        name: String
    ) async -> Provider? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let provider = try await APIClient.shared.createProvider(name: name)
            return provider
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func updateProvider(
        providerId: Int,
        name: String
    ) async -> Provider? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let provider = try await APIClient.shared.updateProvider(
                providerId: providerId,
                name: name
            )
            return provider
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
