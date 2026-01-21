//
//  CreateUserView.swift
//  BillsApp
//
//  Created by Elen Hayot on 20/01/2026.
//

import Foundation
import SwiftUI

struct UserFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel : UserFormViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // Layout pour macOS
    private var macOSLayout: some View {
        VStack(spacing: 24) {
            headerSection
            formSection
            createButton
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .frame(width: 400)
        .padding(40)
    }
    
    // Layout pour iOS
    private var iOSLayout: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    createButton
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationTitle("Bienvenue")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
    
    // Section d'en-tête
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Créer votre compte")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Aucun utilisateur n'existe encore")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // Formulaire
    private var formSection: some View {
        VStack(spacing: 16) {
            #if os(macOS)
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
            
            SecureField("Mot de passe", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
            
            SecureField("Confirmer le mot de passe", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
            #else
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Mot de passe", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
            
            SecureField("Confirmer le mot de passe", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
            #endif
        }
    }
    
    // Bouton de création
    private var createButton: some View {
        Button(action: createUser) {
            if isLoading {
                ProgressView()
                    #if os(iOS)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    #endif
                    .frame(maxWidth: .infinity)
            } else {
                Text("Créer mon compte")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isLoading || !isFormValid)
    }
    
    // Validation du formulaire
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        email.contains("@")
    }
    
    // Création de l'utilisateur
    private func createUser() {
        guard isFormValid else {
            errorMessage = "Veuillez remplir tous les champs correctement"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // 1. Créer l'utilisateur
                try await viewModel.createUser(email: email, password: password)
                
                // 2. Connecter automatiquement l'utilisateur
                await authViewModel.login(email: email, password: password)
                
                // 3. Mettre à jour hasUsers dans AuthViewModel
                authViewModel.hasUsers = true
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
