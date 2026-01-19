//
//  ProviderFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import SwiftUI

struct ProviderFormView: View {
    
    let provider: Provider? // nil = création, non-nil = édition
    let onSaved: (Provider) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProviderFormViewModel()
    
    @State private var name: String
    
    init(provider: Provider? = nil, onSaved: @escaping (Provider) -> Void) {
        self.provider = provider
        self.onSaved = onSaved
        
        // Initialise les states avec les valeurs existantes ou par défaut
        _name = State(initialValue: provider?.name ?? "")
    }
    
    var isEditing: Bool {
        provider != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(isEditing ? "Editer" : "Nouveau fournisseur")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.isLoading {
                ProgressView("Chargement des fournisseurs...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Titre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom")
                                .font(.headline)
                            
                            TextField("Nom du fournisseur", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                // Boutons d'action
                HStack(spacing: 16) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        Task {
                            await saveProvider()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isEditing ? "Sauvegarder" : "Créer")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || viewModel.isSaving)
                }
            }
        }
        .padding()
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty
    }
    
    private func saveProvider() async {
        let savedProvider: Provider?
        
        if let existingProvider = provider {
            // Édition
            savedProvider = await viewModel.updateProvider(
                providerId: existingProvider.id,
                name: name
            )
        } else {
            // Création
            savedProvider = await viewModel.createProvider(name: name)
        }
        
        if let savedProvider = savedProvider {
            onSaved(savedProvider)
            dismiss()
        }
    }
}

