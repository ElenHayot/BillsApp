//
//  BillFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct BillFormView: View {
    
    let token: String
    let bill: Bill? // nil = création, non-nil = édition
    let defaultCategoryId: Int?
    let onSaved: (Bill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BillFormViewModel()
    
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var selectedCategoryId: Int?
    @State private var comment: String
    
    init(token: String, bill: Bill? = nil, defaultCategoryId: Int? = nil, onSaved: @escaping (Bill) -> Void) {
        self.token = token
        self.bill = bill
        self.defaultCategoryId = defaultCategoryId
        self.onSaved = onSaved
        
        // Initialise les states avec les valeurs existantes ou par défaut
        _title = State(initialValue: bill?.title ?? "")
        _amount = State(initialValue: bill != nil ? "\(bill!.amount)" : "")
        _date = State(initialValue: bill?.date ?? Date())
        _selectedCategoryId = State(initialValue: bill?.categoryId ?? defaultCategoryId)
        _comment = State(initialValue: bill?.comment ?? "")
    }
    
    var isEditing: Bool {
        bill != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(isEditing ? "Edit Bill" : "New Bill")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.isLoading {
                ProgressView("Loading categories...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Titre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                            
                            TextField("Bill title", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Montant
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
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
                            Text("Category")
                                .font(.headline)
                            
                            if viewModel.categories.isEmpty {
                                Text("No categories available")
                                    .foregroundColor(.secondary)
                            } else {
                                Picker("Select category", selection: $selectedCategoryId) {
                                    Text("Select a category").tag(nil as Int?)
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
                        
                        // Commentaire
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comment (optional)")
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
                    Button("Cancel") {
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
                            Text(isEditing ? "Save" : "Create")
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
            await viewModel.loadCategories(token: token)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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
              let categoryId = selectedCategoryId else {
            return
        }
        
        let savedBill: Bill?
        
        if let existingBill = bill {
            // Édition
            savedBill = await viewModel.updateBill(
                token: token,
                billId: existingBill.id,
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                comment: comment.isEmpty ? nil : comment
            )
        } else {
            // Création
            savedBill = await viewModel.createBill(
                token: token,
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                comment: comment.isEmpty ? nil : comment
            )
        }
        
        if let savedBill = savedBill {
            onSaved(savedBill)
            dismiss()
        }
    }
}
