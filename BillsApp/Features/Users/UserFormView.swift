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
    
    // MARK: - subviews
    
    // Layout pour macOS
    private var macOSLayout: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Formulaire
                    formCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Actions
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .frame(width: 400)
    }
    
    // Layout pour iOS
    private var iOSLayout: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Formulaire
                    formCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Actions
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("Bienvenue")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Créer votre compte")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Aucun utilisateur n'existe encore")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: 20) {
            // Email
            formField(
                title: "Email",
                placeholder: "votre@email.com",
                text: $email,
                keyboardType: .emailAddress
            )
            
            // Mot de passe
            formSecureField(
                title: "Mot de passe",
                placeholder: "Au moins 8 caractères",
                text: $password
            )
            
            // Confirmation du mot de passe
            formSecureField(
                title: "Confirmer le mot de passe",
                placeholder: "Répétez le mot de passe",
                text: $confirmPassword
            )
            
            // Indicateur de force du mot de passe
            passwordHint
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 16) {
            // Message d'erreur
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Bouton de création
            Button(action: createUser) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                    }
                    
                    Text("Créer mon compte")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isFormValid ? [Color.blue, Color.blue.opacity(0.85)] : [Color.gray, Color.gray.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(isLoading || !isFormValid)
        }
        .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // Affichage des règles de mot de passe
    @ViewBuilder
    private var passwordHint: some View {
        if !password.isEmpty && password.count < 8 {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Au moins 8 caractères requis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - helpers
    
    private func formField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                #if os(iOS)
                .keyboardType(keyboardType)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                #endif
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func formSecureField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            SecureField(placeholder, text: text)
                #if os(iOS)
                .textContentType(.newPassword)
                #endif
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
    
    // Fortification du mot de passe
    struct PasswordValidator {
        static func validate(_ password: String) -> PasswordStrength {
            let minLength = 8
            
            if password.count < minLength {
                return PasswordStrength(
                    isValid: false,
                    message: "Le mot de passe doit contenir au moins \(minLength) caractères"
                )
            }
            
            return PasswordStrength(isValid: true, message: "Mot de passe valide")
        }
    }

    // Validation du mot de passe
    struct PasswordStrength {
        let isValid: Bool
        let message: String
    }
}
