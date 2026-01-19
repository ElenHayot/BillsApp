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

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                   Text("Fournisseurs")
                       .font(.largeTitle)
               }
                
                Spacer()
                
                // Bouton créer
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)

            if viewModel.isLoading {
                ProgressView("Chargement des fournisseurs…")
            }
            else if let error = viewModel.errorMessage {
                ErrorView(
                    message: error,
                    retryAction: {
                        Task { await viewModel.loadProviders() }
                    }
                )
            }
            else if viewModel.providers.isEmpty {
               EmptyStateView(
                        icon: "doc.text",
                        title: "Aucun fournisseur",
                        message: "Tu n'as pas encore de fournisseur enregistré.",
                        actionTitle: "Ajouter un fournisseur",
                        action: {
                            showCreateForm = true
                        }
                   )
            } else {
                List(viewModel.providers) { provider in
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
                }
            }
        }
        .padding()
        .task {
            await viewModel.loadProviders()
        }
        .navigationDestination(for: Provider.self) { provider in
            ProviderDetailView(provider: provider)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            ProviderFormView() { newProvider in
                handleProviderCreated(newProvider)
            }
        }
        .sheet(item: $providerToEdit) { provider in
            ProviderFormView(provider: provider) { updatedProvider in
                handleProviderUpdated(updatedProvider)
            }
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
    }
    
    // Gère la création - met à jour la liste
    private func handleProviderCreated(_ newProvider: Provider) {
        viewModel.providers.append(newProvider)
    }
    
    // Gère la mise à jour
    private func handleProviderUpdated(_ updatedProvider: Provider) {
        if let index = viewModel.providers.firstIndex(where: { $0.id == updatedProvider.id }) {
            viewModel.providers[index] = updatedProvider
        }

    }
    
    private func deleteProvider(_ provider: Provider) async {
        await viewModel.deleteProvider(providerId: provider.id)
        providerToDelete = nil
    }
}
