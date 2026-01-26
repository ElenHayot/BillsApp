//
//  BillFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI
import Foundation

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
    
    // 🆕 Alert pour création de provider
    @State private var showProviderAlert = false
    @State private var providerToCreate: String = ""
    
    // 🆕 Focus pour iOS (permet de gérer le clavier)
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, amount, providerName, comment
    }
    
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
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Formulaire
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
            .background(Color(UIColor.systemGroupedBackground))
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
        .alert("Créer un nouveau fournisseur ?", isPresented: $showProviderAlert) {
            Button("Non") {
                // Créer la facture sans le provider
                Task {
                    await saveBillForceWithoutProvider()
                }
            }
            Button("Oui") {
                Task {
                    await createNewProvider()
                }
            }
        } message: {
            Text("Le fournisseur \"\(providerToCreate)\" n'existe pas. Souhaitez-vous le créer ?")
        }
    }
    
    // MARK: - Subviews
        
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditing ? "Éditer la facture" : "Nouvelle facture")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if isEditing {
                        Text("Modifie les informations de la facture")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ajoute une nouvelle facture à ta collection")
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
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var formCard: some View {
        VStack(spacing: 20) {
            // Titre
            formField(
                title: "Titre",
                placeholder: "Titre de la facture",
                text: $title,
                field: .title
            )
            
            // Montant
            formField(
                title: "Montant",
                placeholder: "0.00",
                text: $amount,
                field: .amount,
                keyboardType: .decimalPad
            )
            
            // Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    #if os(iOS)
                    .datePickerStyle(.automatic)
                    #else
                    .datePickerStyle(.compact)
                    #endif
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Catégorie
            VStack(alignment: .leading, spacing: 8) {
                Text("Catégorie")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.categories.isEmpty {
                    Text("Pas de catégorie disponible")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Fournisseur
            VStack(alignment: .leading, spacing: 8) {
                Text("Fournisseur (optionnel)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.providers.isEmpty {
                    Text("Pas de fournisseur disponible")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Picker("Sélectionner fournisseur", selection: $selectedProviderId) {
                        Text("Sélectionne un fournisseur").tag(nil as Int?)
                        ForEach(viewModel.providers) { provider in
                            Text(provider.name).tag(provider.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Nom du fournisseur
            formTextArea(
                title: "Nom du fournisseur (optionnel)",
                text: $providerName,
                field: .providerName
            )
            
            // Commentaire
            formTextArea(
                title: "Commentaire (optionnel)",
                text: $comment,
                field: .comment
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var actionsCard: some View {
        HStack(spacing: 16) {
            Button("Annuler") {
                dismiss()
            }
            .foregroundColor(.blue)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .buttonStyle(.plain)
            
            Button {
                Task {
                    await saveBill()
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
    
    // MARK: - Helpers
    
    private func formField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                #if os(iOS)
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field)
                .autocapitalization(.words)
                #endif
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func formTextArea(
        title: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: text)
                #if os(iOS)
                .focused($focusedField, equals: field)
                #endif
                .frame(height: 80)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
              let categoryId = selectedCategoryId
        else {
            return
        }
        
        // Mettre à jour le selectedProviderId si on trouve un provider correspondant
        if selectedProviderId == nil {
            selectedProviderId = await detecteProviderId(name: providerName)
        }
        
        // Vérifier si on doit créer un provider
        if shouldCreateProvider() {
            providerToCreate = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
            showProviderAlert = true
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
    
    // Vérifie s'il existe un provider correspondant au nom détecté
    private func detecteProviderId(name: String) async -> Int? {
        if let existingProvider = await viewModel.fetchProvider(name: name) {
            return existingProvider.id
        }
        return nil
    }
    
    // Logique de détection de provider à créer
    private func shouldCreateProvider() -> Bool {
        let trimmedName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Vérifier si un nom est renseigné mais aucun provider sélectionné
        guard !trimmedName.isEmpty, selectedProviderId == nil else {
            return false
        }
        
        // Vérifier si le provider n'existe pas déjà dans la liste
        let providerExists = viewModel.providers.contains { provider in
            provider.name.lowercased() == trimmedName.lowercased()
        }
        
        return !providerExists
    }
    
    // Forcer la sauvegarde sans créer le provider
    private func saveBillForceWithoutProvider() async {
        guard let amountDecimal = Decimal(string: amount),
              let categoryId = selectedCategoryId
        else {
            return
        }
        
        // Garder le providerName mais vider selectedProviderId pour créer la facture avec le nom mais sans l'ID
        let providerId: Int? = nil
        // NE PAS vider providerName pour garder le nom pré-rempli
        
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
    
    // Créer le nouveau provider
    private func createNewProvider() async {
        let providerViewModel = ProviderFormViewModel()
        
        if let newProvider = await providerViewModel.createProvider(name: providerToCreate) {
            // Recharger la liste des providers
            await viewModel.loadProviders()
            
            // Sélectionner automatiquement le nouveau provider
            if let createdProvider = viewModel.providers.first(where: { $0.name.lowercased() == providerToCreate.lowercased() }) {
                selectedProviderId = createdProvider.id
                providerName = createdProvider.name
            }
            
            // Relancer la sauvegarde de la facture
            await saveBill()
        }
    }
}
