//
//  ContentView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSettings = false
    @State private var showUserEdit = false
    @State private var showLogoutConfirmation = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                SplashView()
            }
            else if authViewModel.isAuthenticated {
                MainNavigationView(navigationPath: $navigationPath)
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showUserEdit) {
                    UserEditView()
                }
                .alert("Se déconnecter ?", isPresented: $showLogoutConfirmation) {
                    Button("Se déconnecter", role: .destructive) {
                        authViewModel.logout()
                        showSettings = false
                    }
                    Button("Annuler", role: .cancel) {}
                } message: {
                    Text("Êtes-vous sûr de vouloir vous déconnecter ?")
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }
}
