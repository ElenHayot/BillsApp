//
//  UserEditView.swift
//  BillsApp
//
//  Created by Elen Hayot on 26/01/2026.
//

import SwiftUI

struct UserEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserEditViewModel()
    
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPasswordChange = false
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Email Card
                    emailCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Password Card
                    passwordCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Actions Card
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            loadUserData()
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Succès", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
                if viewModel.shouldDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modifier mon profil")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Mets à jour tes informations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Email Card
    
    private var emailCard: some View {
        VStack(spacing: 20) {
            formField(
                title: "Email",
                placeholder: "votre@email.com",
                text: $email,
                keyboardType: .emailAddress
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Password Card
    
    private var passwordCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Mot de passe")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(showPasswordChange ? "Masquer" : "Modifier") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPasswordChange.toggle()
                    }
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
            
            if showPasswordChange {
                VStack(spacing: 16) {
                    formSecureField(
                        title: "Mot de passe actuel",
                        placeholder: "Entrez votre mot de passe actuel",
                        text: $currentPassword
                    )
                    
                    formSecureField(
                        title: "Nouveau mot de passe",
                        placeholder: "Au moins 8 caractères",
                        text: $newPassword
                    )
                    
                    formSecureField(
                        title: "Confirmer le nouveau mot de passe",
                        placeholder: "Répétez le nouveau mot de passe",
                        text: $confirmPassword
                    )
                    
                    if !newPassword.isEmpty && newPassword.count < 8 {
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 16) {            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
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
            
            // Saving button
            Button {
                Task {
                    await saveChanges()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                    }
                    
                    Text("Sauvegarder les modifications")
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
            .disabled(viewModel.isLoading || !isFormValid)
        }
        .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 8, x: 0, y: 2)
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Helpers
    
    private func loadUserData() {
        if let user = authViewModel.currentUser {
            email = user.email
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && (
            !showPasswordChange || (
                !currentPassword.isEmpty && 
                !newPassword.isEmpty && 
                !confirmPassword.isEmpty && 
                newPassword == confirmPassword &&
                newPassword.count >= 8
            )
        )
    }
    
    private func saveChanges() async {
        guard isFormValid else { return }
        
        do {
            // currentUser already updated in APIService
            try await viewModel.updateUser(
                email: email,
                password: showPasswordChange ? newPassword : currentPassword
            )
            
        } catch {
        }
    }
    
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
}

#Preview {
    NavigationView {
        UserEditView()
            .environmentObject(AuthViewModel())
    }
}
