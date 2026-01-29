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

    var body: some View {
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

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
