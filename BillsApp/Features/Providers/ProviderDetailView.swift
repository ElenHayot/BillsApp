//
//  ProviderDetailView.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import SwiftUI

struct ProviderDetailView: View {

    let provider: Provider
    let onSuccess: (String) -> Void
    
    @EnvironmentObject private var listViewModel: ProvidersListViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ProviderDetailViewModel()
    @State private var showDeleteConfirmation = false
    
    init(provider: Provider, onSuccess: @escaping (String) -> Void = { _ in }) {
        self.provider = provider
        self.onSuccess = onSuccess
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Actions
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            #if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            #endif
        }
        .alert("Supprimer ce fournisseur ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = try await viewModel.deleteProvider(
                        providerId: provider.id
                    )
                    if success {
                        listViewModel.providers.removeAll { $0.id == provider.id }
                        if let message = viewModel.successMessage {
                            onSuccess(message)
                            viewModel.successMessage = nil
                        }
                        dismiss()
                    } else {
                        print("❌ Échec de la suppression")
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(provider.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("ID: \(provider.id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                }
                
                Spacer()
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    if viewModel.isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .font(.title3)
                    }
                    
                    Text("Supprimer le fournisseur")
                        .font(.headline)
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDeleting)
        }
        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}
