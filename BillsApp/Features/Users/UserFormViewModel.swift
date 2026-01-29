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
        
        @Published var isLoading = false
        @Published var errorMessage: String?
        
        func createUser(email: String, password: String) async throws -> User? {
            isLoading = true
            errorMessage = nil
            
            do {
                let response = try await APIClient.shared.createUser(
                    email: email,
                    password: password
                )
                
                // Set hasUsers = true
                UserDefaults.standard.set(true, forKey: "hasUsers")
                
                isLoading = false
                
                return response
                
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de la création du compte"
                throw error
            }
        }
    }
