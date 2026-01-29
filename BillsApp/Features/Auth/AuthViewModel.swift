//
//  AuthViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 31/12/2025.
//  ViewModel to manage authentication state
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
            // Check if refresh token exists when launching app
            await checkAuthenticationState()
        }
    }
    
    @MainActor
    func checkIfUsersExist() async {
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
    /// Check if user already connected when launching app
    private func checkAuthenticationState() async {
        if let token = AuthStorage.shared.accessToken,
           KeychainManager.shared.getRefreshToken() != nil {
            accessToken = token
            isAuthenticated = true
            hasUsers = true
            isCheckingUsers = false
        } else if KeychainManager.shared.getRefreshToken() != nil {
            await attemptTokenRefresh()
            hasUsers = true
            isCheckingUsers = false
        } else {
            print("❓ Pas de token, vérification des utilisateurs...")
            await checkIfUsersExist()
        }
    }
    
    // MARK: - Attempt Token Refresh
    /// Try to get new access token with current refresh token
    private func attemptTokenRefresh() async {
        do {
            try await APIClient.shared.refreshAccessToken()
        } catch {
            logout()
        }
    }

    // MARK: - Login
    /// Login user with email and password
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.login(
                email: email,
                password: password
            )
            
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
    /// Logout user and clear tokens
    func logout() {
        Task {
            do {
                try await APIClient.shared.logout()
                print("✅ Logout réussi")
            } catch {
                print("⚠️ Erreur lors du logout serveur: \(error)")
            }
            
            await MainActor.run {
                AuthStorage.shared.accessToken = nil
                KeychainManager.shared.deleteRefreshToken()
                accessToken = nil
                isAuthenticated = false
            }
        }
    }
}
