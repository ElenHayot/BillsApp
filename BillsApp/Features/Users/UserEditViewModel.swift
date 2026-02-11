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
    
    func updateUser(userId: Int, email: String, password: String? = nil) async throws -> User {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await APIClient.shared.updateUser(userId: userId, email: email, password: password)
            
            successMessage = "Profil mis à jour avec succès"
            shouldDismiss = true
            isLoading = false
            
            return response
            
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
