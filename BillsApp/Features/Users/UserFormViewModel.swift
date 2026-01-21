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
                // 1. Créer l'utilisateur via l'API
                let response = try await APIClient.shared.createUser(
                    email: email,
                    password: password
                )
                
                // 2. Marquer qu'un utilisateur existe maintenant
                UserDefaults.standard.set(true, forKey: "hasUsers")
                
    //
    //            // 3. Se connecter
    //            do {
    //                let loginResponse = try await APIClient.shared.login(
    //                    email: email,
    //                    password: password
    //                )
    //                print("✅ Utilisateur créé et connecté")
    //            } catch {
    //                // Si le login échoue, l'user existe quand même
    //                // On pourrait rediriger vers la page de login
    //                print("⚠️ Utilisateur créé mais erreur de connexion")
    //                throw NSError(
    //                    domain: "CreateUser",
    //                    code: 1,
    //                    userInfo: [NSLocalizedDescriptionKey: "Compte créé. Veuillez vous connecter."]
    //                )
    //            }
                isLoading = false
                
                return response
                
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de la création du compte"
                throw error
            }
        }
    }
