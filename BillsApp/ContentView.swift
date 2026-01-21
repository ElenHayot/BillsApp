//
//  ContentView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

// MARK: - Root View
/// Vue racine qui décide quelle vue afficher selon l'état d'authentification
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Utilisateur connecté → Dashboard
                DashboardView()
            } else if authViewModel.hasUsers {
                // Des utilisateurs existent → Login
                LoginView()
            } else {
                // Aucun utilisateur → Création du premier user
                UserFormView()
            }
        }
        // Animation fluide lors du changement d'état
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }
}
