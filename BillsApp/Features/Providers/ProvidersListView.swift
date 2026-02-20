//
//  ProvidersListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import SwiftUI

struct ProvidersListView: View {

    @State private var showFilters = false
    
    @StateObject private var viewModel = ProvidersListViewModel()
    @State private var showCreateForm = false
    @State private var providerToEdit: Provider?
    @State private var providerToDelete: Provider?
    @State private var showDeleteConfirmation = false
    @State var year: Int
    @State var showToast: Bool = false
    @State var toastMessage: String = ""
    
    init(year: Int) {
        self.year = year
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content
                    contentView
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .background(Color.systemGroupedBackground)
            
            if showToast {
                VStack {
                    Text(toastMessage)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)  // ← Assure it's over all
            }
        }
        .task {
            await viewModel.loadProviders()
        }
        .navigationDestination(for: Provider.self) { provider in
            ProviderDetailView(provider: provider)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            ProviderFormView(
                onSaved: {
                    newProvider in
                        handleProviderCreated(newProvider)
                },
                onSuccess: { message in
                    showSuccessToast(message ?? "")
                }
            )
        }
        .sheet(item: $providerToEdit) { provider in
            ProviderFormView(
                provider: provider,
                onSaved: { updatedProvider in
                    handleProviderUpdated(updatedProvider)
                },
                onSuccess: { message in
                    showSuccessToast(message ?? "")
                }
            )
        }
        .alert("Supprimer ce fournisseur ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                if let provider = providerToDelete {
                    Task {
                        await deleteProvider(provider)
                    }
                }
            }
            Button("Annuler", role: .cancel) {
                providerToDelete = nil
            }
        } message: {
            if let provider = providerToDelete {
                Text("Es-tu sûr de vouloir supprimer le fournisseur '\(provider.name)' ?")
            }
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fournisseurs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Gère tes fournisseurs de factures")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Chargement des fournisseurs...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if let error = viewModel.errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.body)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Réessayer") {
                    Task { await viewModel.loadProviders() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if viewModel.providers.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Aucun fournisseur")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Tu n'as pas encore de fournisseur enregistré.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Ajouter un fournisseur") {
                    showCreateForm = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.providers) { provider in
                    NavigationLink(value: provider) {
                        ProviderRowView(
                            provider: provider,
                            onEdit: {
                                providerToEdit = provider
                            },
                            onDelete: {
                                providerToDelete = provider
                                showDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if provider.id != viewModel.providers.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - helpers
    
    // Manage provider creation - update local list
    private func handleProviderCreated(_ newProvider: Provider) {
        viewModel.providers.append(newProvider)
    }
    
    // Manage updating
    private func handleProviderUpdated(_ updatedProvider: Provider) {
        if let index = viewModel.providers.firstIndex(where: { $0.id == updatedProvider.id }) {
            viewModel.providers[index] = updatedProvider
        }

    }
    
    private func deleteProvider(_ provider: Provider) async {
        do {
            try await viewModel.deleteProvider(providerId: provider.id)
            providerToDelete = nil
        } catch {}
    }
    
    /// Show toast on success message received
    private func showSuccessToast(_ message: String) {
        Task { @MainActor in
            // Sleep to let last UI called close
            try? await Task.sleep(nanoseconds: 100_000_000)
            toastMessage = message
            withAnimation {
                showToast = true
            }
            
            // sleep instead of async call
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                showToast = false
            }
        }
    }
}
