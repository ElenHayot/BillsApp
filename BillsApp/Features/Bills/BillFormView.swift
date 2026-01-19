//
//  BillFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct BillFormView: View {
    
    let bill: Bill? // nil = création, non-nil = édition
    let defaultCategoryId: Int?
    let onSaved: (Bill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BillFormViewModel()
    
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var selectedCategoryId: Int?
    @State private var selectedProviderId: Int?
    @State private var providerName: String
    @State private var comment: String
    
    init(bill: Bill? = nil, defaultCategoryId: Int? = nil, onSaved: @escaping (Bill) -> Void) {
        self.bill = bill
        self.defaultCategoryId = defaultCategoryId
        self.onSaved = onSaved
        
        // Initialise les states avec les valeurs existantes ou par défaut
        _title = State(initialValue: bill?.title ?? "")
        _amount = State(initialValue: bill != nil ? "\(bill!.amount)" : "")
        _date = State(initialValue: bill?.date ?? Date())
        _selectedCategoryId = State(initialValue: bill?.categoryId ?? defaultCategoryId)
        _selectedProviderId = State(initialValue: bill?.providerId ?? nil as Int?)
        _providerName = State(initialValue: bill?.providerName ?? "")
        _comment = State(initialValue: bill?.comment ?? "")
    }
    
    var isEditing: Bool {
        bill != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(isEditing ? "Editer" : "Nouvelle facture")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.isLoading {
                ProgressView("Chargement des factures...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Titre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titre")
                                .font(.headline)
                            
                            TextField("Titre de la facture", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Montant
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Montant")
                                .font(.headline)
                            
                            TextField("0.00", text: $amount)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                            
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                        
                        // Catégorie
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Catégorie")
                                .font(.headline)
                            
                            if viewModel.categories.isEmpty {
                                Text("Pas de catégorie disponible")
                                    .foregroundColor(.secondary)
                            } else {
                                Picker("Selectionner catégorie", selection: $selectedCategoryId) {
                                    Text("Selectionne une catégorie").tag(nil as Int?)
                                    ForEach(viewModel.categories) { category in
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color(hex: category.color))
                                                .frame(width: 12, height: 12)
                                            Text(category.name)
                                        }
                                        .tag(category.id as Int?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        
                        // Fournisseur
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fournisseur (optionnel)")
                                .font(.headline)
                            
                            if viewModel.providers.isEmpty {
                                Text("Pas de fournisseur disponible")
                                    .foregroundColor(.secondary)
                            } else {
                                Picker("Selectionner fournisseur", selection: $selectedProviderId) {
                                    Text("Selectionne un fournisseur").tag(nil as Int?)
                                    ForEach(viewModel.providers) { provider in
                                        HStack(spacing: 8) {
                                            Text(String(provider.id))
                                            Spacer()
                                            Text(provider.name)
                                        }
                                        .tag(provider.id as Int?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        
                        /// Nom du fournisseur
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom du fournisseur (optionnel)")
                                .font(.headline)
                            
                            TextEditor(text: $providerName)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Commentaire
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Commentaire (optionnel)")
                                .font(.headline)
                            
                            TextEditor(text: $comment)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
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
                            await saveBill()
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
        .task {
            await viewModel.loadCategories()
        }
        .task {
            await viewModel.loadProviders()
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !amount.isEmpty &&
        Decimal(string: amount) != nil &&
        selectedCategoryId != nil
    }
    
    private func saveBill() async {
        guard let amountDecimal = Decimal(string: amount),
              let categoryId = selectedCategoryId,
              let providerId = selectedProviderId ?? nil as Int?
        else {
            return
        }
        
        let savedBill: Bill?
        
        if let existingBill = bill {
            // Édition
            savedBill = await viewModel.updateBill(
                billId: existingBill.id,
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName.isEmpty ? "" : providerName,
                comment: comment.isEmpty ? "" : comment
            )
        } else {
            // Création
            savedBill = await viewModel.createBill(
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName.isEmpty ? "" : providerName,
                comment: comment.isEmpty ? "" : comment
            )
        }
        
        if let savedBill = savedBill {
            onSaved(savedBill)
            dismiss()
        }
    }
}
