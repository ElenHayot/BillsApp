//
//  CreateUserViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 20/01/2026.
//

import Foundation
import Combine

@MainActor
final class UserFormViewModel: ObservableObject {
    
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    func createUser(email: String, password: String) async throws -> User? {
        isCreating = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.createUser(
                email: email,
                password: password
            )
            
            // Set hasUsers = true
            UserDefaults.standard.set(true, forKey: "hasUsers")
            successMessage = "Profil créé avec succès"
            isCreating = false
            
            return response
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isCreating = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isCreating = false
            throw error
        }
    }
}
