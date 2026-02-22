//
//  LoginView.swift
//  BillsApp
//  Created by Elen Hayot on 29/12/2025.
//
//  Login view to authenticate
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showUserForm = false
    @FocusState private var focusedField: Field?
    
    enum Field { case email, password }

    var body: some View {
        NavigationStack() {
            VStack(spacing: 16) {

                Text("Connexion")
                    .font(.largeTitle)
                
                TextField("Email", text: $email)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .textFieldStyle(.roundedBorder)

                SecureField("Mot de passe", text: $password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        guard !email.isEmpty && !password.isEmpty else { return }
                        Task { await authVM.login(email: email, password: password) }
                    }
                    .textFieldStyle(.roundedBorder)
//                    .onChange(of: password) { _, newValue in
//                        // Si les deux champs sont remplis (autofill Face ID vient de compléter)
//                        guard !email.isEmpty && !newValue.isEmpty else { return }
//                        Task {
//                            await authVM.login(email: email, password: password)
//                        }
//                    }

                if authVM.isLoading {
                    ProgressView()
                }

                Button("Connexion") {
                    Task {
                        await authVM.login(email: email, password: password)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty)
                
                Divider()
                
                Button("Créer un compte") {
                    showUserForm = true
                }
                .foregroundColor(.blue)

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .navigationDestination(isPresented: $showUserForm) {
                UserFormView()
            }
        }
    }
}
