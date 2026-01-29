//
//  AuthViewModel.swift
//  BillsApp
//
//  ViewModel pour gérer l'état d'authentification de l'app
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var accessToken: String?
    @Published var hasUsers = false
    @Published var currentUser: User?
    @Published var tokenType: String?
    @Published var isCheckingUsers = true
    
    init() {
        Task {
            // Au démarrage, vérifier si on a un refresh token valide
            await checkAuthenticationState()
        }
    }
    
    @MainActor
    func checkIfUsersExist() async {
        // Vérifie s'il existe des utilisateurs dans ta base de données
        // Exemple avec UserDefaults (à adapter selon ton système de stockage)
//        hasUsers = UserDefaults.standard.object(forKey: "hasUsers") != nil
        do {
            let users = try await APIClient.shared.fetchUsers()
            hasUsers = !users.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            hasUsers = false
            print("❌ Erreur lors de la vérification des users: \(error)")
        }
    }
    
    // MARK: - Check Authentication State
    /// Vérifie si l'utilisateur est déjà connecté au démarrage de l'app
    private func checkAuthenticationState() async {
        // Si on a un access token en mémoire ET un refresh token dans le Keychain
        if let token = AuthStorage.shared.accessToken,
           KeychainManager.shared.getRefreshToken() != nil {
            accessToken = token
            isAuthenticated = true
            hasUsers = true
            isCheckingUsers = false
        } else if KeychainManager.shared.getRefreshToken() != nil {
            // Si on a seulement un refresh token, on peut tenter un refresh
            await attemptTokenRefresh()
            hasUsers = true
            isCheckingUsers = false
        } else {
            print("❓ Pas de token, vérification des utilisateurs...")
            // Si pas de token ni de refresh, on vérifie qu'il existe au moins un compte utilisateur
            await checkIfUsersExist()
        }
    }
    
    // MARK: - Attempt Token Refresh
    /// Tente de récupérer un nouveau access token avec le refresh token
    private func attemptTokenRefresh() async {
        do {
            // Simuler une requête qui va déclencher le refresh automatique
            // En pratique, le refresh se fera automatiquement lors de la première requête API
            // Ici on pourrait faire un appel à un endpoint de "check" ou attendre la première requête
            try await APIClient.shared.fetchCategories()
            print("✅ Refresh token disponible, l'utilisateur sera reconnecté automatiquement")
        } catch {
            // Si ça échoue, on déconnecte
            logout()
        }
    }

    // MARK: - Login
    /// Connecte l'utilisateur avec email et password
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.login(
                email: email,
                password: password
            )
            
            // Les tokens sont déjà sauvegardés dans APIClient.login()
            accessToken = response.accessToken
            currentUser = response.currentUser
            tokenType = response.tokenType
            isAuthenticated = true
            
            print("✅ Login réussi")

        } catch {
            errorMessage = "Échec de la connexion. Vérifiez vos identifiants."
            print("❌ Login error: \(error)")
        }
        
        isLoading = false
        isCheckingUsers = false
    }

    // MARK: - Logout
    /// Déconnecte l'utilisateur et nettoie tous les tokens
    func logout() {
        Task {
            do {
                // Appeler le endpoint de logout (qui supprime le refresh token côté serveur)
                try await APIClient.shared.logout()
                print("✅ Logout réussi")
            } catch {
                print("⚠️ Erreur lors du logout serveur: \(error)")
            }
            
            // Nettoyer l'état local quoi qu'il arrive
            await MainActor.run {
                AuthStorage.shared.accessToken = nil
                KeychainManager.shared.deleteRefreshToken()
                accessToken = nil
                isAuthenticated = false
            }
        }
    }
}
