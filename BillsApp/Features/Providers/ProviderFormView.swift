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
    
    // 🆕 Focus pour iOS (permet de gérer le clavier)
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
    }
    
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
        NavigationStack {
            VStack(spacing: 20) {
                Text(isEditing ? "Editer" : "Nouveau fournisseur")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                formContent
                
                actionButtons
                
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                // Barre d'outils clavier iOS
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        focusedField = nil
                    }
                }
            }
            #endif
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
    
    // MARK: - subviews
    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Titre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom")
                        .font(.headline)
                    
                    TextField("Nom du fournisseur", text: $name)
                        #if os(iOS)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
            }
        }
    }
    
    private var actionButtons: some View {
        // Boutons d'action
        HStack(spacing: 16) {
            #if os(macOS)
            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(.bordered)
            #endif
            
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
    
    // MARK: - helpers
    
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

