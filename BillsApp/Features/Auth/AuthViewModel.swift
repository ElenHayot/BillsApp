//
//  AuthViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//

import Foundation
import Combine


class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false

    func login() {
        isAuthenticated = true
    }

    func logout() {
        isAuthenticated = false
    }
}
