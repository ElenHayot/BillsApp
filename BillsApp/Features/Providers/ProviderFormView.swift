//
//  ProviderFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import SwiftUI

struct ProviderFormView: View {
    
    let provider: Provider? // nil = creating, non-nil = editing
    let onSaved: (Provider) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProviderFormViewModel()
    
    @State private var name: String
    @FocusState private var focusedField: Field?    // IOS focus
    
    enum Field {
        case name
    }
    
    init(provider: Provider? = nil, onSaved: @escaping (Provider) -> Void) {
        self.provider = provider
        self.onSaved = onSaved
        
        _name = State(initialValue: provider?.name ?? "")
    }
    
    var isEditing: Bool {
        provider != nil
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Form
                    formCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
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
        .alert("Succès", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
            }
        } message: {
            Text(viewModel.successMessage ?? "")
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
                    Text(isEditing ? "Éditer le fournisseur" : "Nouveau fournisseur")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if isEditing {
                        Text("Modifie le nom du fournisseur")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ajoute un nouveau fournisseur à ta collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: 20) {
            // Name
            formField(
                title: "Nom",
                placeholder: "Nom du fournisseur",
                text: $name,
                field: .name
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        HStack(spacing: 16) {
            Button("Annuler") {
                dismiss()
            }
            .foregroundColor(.blue)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .buttonStyle(.plain)
            
            Button {
                Task {
                    await saveProvider()
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isEditing ? "square.and.arrow.down" : "plus")
                            .font(.title3)
                    }
                    
                    Text(isEditing ? "Sauvegarder" : "Créer")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isFormValid ? [Color.blue, Color.blue.opacity(0.85)] : [Color.gray, Color.gray.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || viewModel.isSaving)
        }
    }
    
    // MARK: - helpers
    
    private func formField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                #if os(iOS)
                .focused($focusedField, equals: field)
                .autocapitalization(.words)
                .background(Color(UIColor.systemGray6))
                #endif
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty
    }
    
    private func saveProvider() async {
        let savedProvider: Provider?
        
        do{
            if let existingProvider = provider {
                // Editing
                savedProvider = try await viewModel.updateProvider(
                    providerId: existingProvider.id,
                    name: name
                )
            } else {
                // Creating
                savedProvider = try await viewModel.createProvider(name: name)
            }
            
            if let savedProvider = savedProvider {
                onSaved(savedProvider)
                dismiss()
            }
        } catch {}
    }
}

