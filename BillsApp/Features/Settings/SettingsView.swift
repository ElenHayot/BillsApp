//
//  SettingsView.swift
//  BillsApp
//
//  Created by Elen Hayot on 26/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    @State private var showUserEdit = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountSuccess = false
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header Card
                        headerCard
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // User Card
                        userCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        // Preferences Card
                        preferencesCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        // About Card
                        aboutCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        // Actions Card
                        actionsCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        
                        // Espace visuel
                        Spacer(minLength: 40)
                        
                        // Danger Zone Card (suppression)
                        dangerZoneCard
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .background(Color.systemGroupedBackground)
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
        }
        .alert("Supprimer le compte et toutes ses données ?", isPresented: $showDeleteAccountConfirmation){
            Button("Supprimer le compte", role: .destructive) {
                Task {
                    authViewModel.deleteUser(userId: AuthStorage.shared.currentUser?.userId ?? 0)
                    showDeleteAccountSuccess = true
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer le compte et toutes ses données ? Attention, cette action est irréversible")
        }
        .alert("Compte utilisateur supprimé avec succès !", isPresented: $showDeleteAccountSuccess) {}
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paramètres")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Personnalise ton expérience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Terminé") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - User Card
    
    private var userCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compte")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let email = authViewModel.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Modifier") {
                    showUserEdit = true
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Preferences Card
    
    private var preferencesCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Préférences")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Thème, langue, notifications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - App Card
    
    private var aboutCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("À propos")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    Text("Se déconnecter")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Danger Zone Card

    private var dangerZoneCard: some View {
        VStack(spacing: 8) {
            Text("Zone dangereuse")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            Button {
                showDeleteAccountConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Supprimer le compte")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
