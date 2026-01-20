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
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Chargement des factures...")
                } else {
                    
                    formContent
                    
                    actionButtons
                        .padding()
                    
                }
            }
            .navigationTitle(isEditing ? "Éditer" : "Nouvelle facture")
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
    
    // MARK: - Subviews
        
    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Titre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titre")
                        .font(.headline)
                    
                    TextField("Titre de la facture", text: $title)
                        #if os(iOS)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .title)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
                
                // Montant
                VStack(alignment: .leading, spacing: 8) {
                    Text("Montant")
                        .font(.headline)
                    
                    TextField("0.00", text: $amount)
                        #if os(iOS)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        #if os(iOS)
                        .datePickerStyle(.automatic) // iOS : roue ou modal
                        #else
                        .datePickerStyle(.compact) // macOS : compact
                        #endif
                }
                
                // Catégorie
                VStack(alignment: .leading, spacing: 8) {
                    Text("Catégorie")
                        .font(.headline)
                    
                    if viewModel.categories.isEmpty {
                        Text("Pas de catégorie disponible")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Sélectionner catégorie", selection: $selectedCategoryId) {
                            Text("Sélectionne une catégorie").tag(nil as Int?)
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
                        Picker("Sélectionner fournisseur", selection: $selectedProviderId) {
                            Text("Sélectionne un fournisseur").tag(nil as Int?)
                            ForEach(viewModel.providers) { provider in
                                Text(provider.name).tag(provider.id as Int?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Nom du fournisseur
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom du fournisseur (optionnel)")
                        .font(.headline)
                    
                    #if os(iOS)
                    // iOS : TextEditor avec hauteur fixe
                    TextEditor(text: $providerName)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .providerName)
                    #else
                    // macOS : TextEditor classique
                    TextEditor(text: $providerName)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    #endif
                }
                
                // Commentaire
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commentaire (optionnel)")
                        .font(.headline)
                    
                    #if os(iOS)
                    TextEditor(text: $comment)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .comment)
                    #else
                    TextEditor(text: $comment)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    #endif
                }
            }
            .padding()
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            #if os(macOS)
            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(.bordered)
            #endif
            
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
    
    // MARK: - helpers
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !amount.isEmpty &&
        Decimal(string: amount) != nil &&
        selectedCategoryId != nil
    }
    
    private func saveBill() async {
        
        guard let amountDecimal = Decimal(string: amount),
              let categoryId = selectedCategoryId
        else {
            return
        }
        
        let providerId = selectedProviderId as Int?
        
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
