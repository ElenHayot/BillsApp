//
//  LoginView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)

            Button("Se connecter") {
                authVM.login()
            }
        }
        .padding()
    }
}
