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

    var body: some View {
        NavigationStack() {
            VStack(spacing: 16) {

                Text("Connexion")
                    .font(.largeTitle)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(.roundedBorder)

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
