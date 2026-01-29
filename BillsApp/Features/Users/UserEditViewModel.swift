//
//  UserEditViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 26/01/2026.
//

import Foundation
import Combine

@MainActor
class UserEditViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shouldDismiss = false
    
    func updateUser(email: String, password: String) async throws -> User {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await APIClient.shared.updateUser(email: email, password: password)
            
            successMessage = "Profil mis à jour avec succès"
            shouldDismiss = true
            isLoading = false
            
            return response
            
        } catch {
            errorMessage = "Erreur lors de la mise à jour : \(error.localizedDescription)"
            isLoading = false
            
            throw error
        }
        
    }
}
