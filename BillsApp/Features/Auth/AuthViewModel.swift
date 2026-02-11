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
    @Published var currentUser: User?
    @Published var tokenType: String?
    
    init() {
        Task {
            // Check if refresh token exists when launching app
            await checkAuthenticationState()
        }
    }
    
    // MARK: - Check Authentication State
    /// Check if user already connected when launching app
    private func checkAuthenticationState() async {
        if let token = AuthStorage.shared.accessToken,
           KeychainManager.shared.getRefreshToken() != nil {
            accessToken = token
            self.currentUser = AuthStorage.shared.currentUser
            isAuthenticated = true
        } else if KeychainManager.shared.getRefreshToken() != nil {
            await attemptTokenRefresh()
        }
    }
    
    // MARK: - Attempt Token Refresh
    /// Try to get new access token with current refresh token
    private func attemptTokenRefresh() async {
        do {
            let _ = try await APIClient.shared.refreshAccessToken()
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

        } catch let error as NetworkError {
            self.errorMessage = error.errorDescription
            self.isLoading = false
        } catch {
            self.errorMessage = "Une erreur inattendue s'est produite"
            self.isLoading = false
        }
        
        isLoading = false
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
    
    // MARK: - Update account info
    func updateCurrentUser(_ user: User) {
        self.currentUser = user
        AuthStorage.shared.currentUser = user
    }
    
    // MARK: - Delete account
    /// Delete a user and all its account data
    func deleteUser(userId: Int) {
        Task {
            do {
                try await APIClient.shared.deleteUser(userId: userId)
            } catch {
                print("⚠️ Erreur serveur lors de la suppression du compte utilisateur : \(error)")
            }
            
            await MainActor.run {
                AuthStorage.shared.accessToken = nil
                AuthStorage.shared.currentUser = nil
                KeychainManager.shared.deleteRefreshToken()
                accessToken = nil
                isAuthenticated = false
            }
        }
    }
    
}
