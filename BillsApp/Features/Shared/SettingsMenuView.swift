//
//  SettingsMenuView.swift
//  BillsApp
//
//  Created by Elen Hayot on 28/01/2026.
//

import Foundation
import Combine
import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSettings = false
    @State private var showUserEdit = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        Menu {
            
            Button {
                showUserEdit = true
            } label: {
                Label("Profil", systemImage: "person.circle")
            }
            
            Button {
                showSettings = true
            } label: {
                Label("Paramètres", systemImage: "gearshape")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Se déconnecter", systemImage: "arrow.right.square")
            }
                
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(.primary)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showUserEdit) {
            UserEditView()
        }
        .alert("Se déconnecter ?", isPresented: $showLogoutConfirmation) {
            Button("Se déconnecter", role: .destructive) {
                Task {
                    authViewModel.logout()
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
        
    }
}

#Preview {
    NavigationView {
        SettingsMenuView()
            .environmentObject(AuthViewModel())
    }
}
