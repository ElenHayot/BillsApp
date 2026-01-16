//
//  AuthSession.swift
//  BillsApp
//
//  Created by Elen Hayot on 13/01/2026.
//

import SwiftUI
import Combine

@MainActor
final class AuthSession: ObservableObject {
    @Published var accessToken: String?
    @Published var isAuthenticated = false

    func logout() {
        accessToken = nil
//        Keychain.deleteRefreshToken()
        isAuthenticated = false
    }
}
