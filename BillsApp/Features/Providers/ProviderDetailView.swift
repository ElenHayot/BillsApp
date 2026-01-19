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
    
    // Récupère le viewModel de la liste
    @EnvironmentObject private var listViewModel: ProvidersListViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ProviderDetailViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(provider.name)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView()
                } else {
                    Text("Supprimer le fournisseur")
                }
            }
        }
        .padding()
        .navigationTitle("Provider")
        .alert("Supprimer ce fournisseur ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = await viewModel.deleteProvider(
                        providerId: provider.id
                    )
                    if success {
                        print("✅ Suppression réussie, suppression locale pour provider \(provider.id)")
                        // ✅ Supprime directement dans le viewModel
                        listViewModel.providers.removeAll { $0.id == provider.id }
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

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
