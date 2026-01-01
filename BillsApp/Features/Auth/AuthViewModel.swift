//
//  AuthViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var accessToken: String?

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.login(
                email: email,
                password: password
            )
            AuthStorage.shared.accessToken = response.accessToken
            isAuthenticated = true

        } catch {
            errorMessage = "Login failed"
        }
        isLoading = false
    }

    func logout() {
        AuthStorage.shared.accessToken = nil
        isAuthenticated = false
        // delete refresh token du Keychain
    }
}
