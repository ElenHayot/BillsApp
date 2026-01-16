//
//  AllBillsListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct AllBillsListView: View {
    
    @State private var selectedYear: Int
    @State private var selectedCategoryId: Int?
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var showFilters = false
    
    @StateObject private var viewModel = AllBillsListViewModel()
    @State private var showCreateForm = false
    @State private var billToEdit: Bill?
    @State private var billToDelete: Bill?
    @State private var showDeleteConfirmation = false
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    // Bills filtrées selon les critères
    private var filteredBills: [BillWithCategory] {
        var bills = viewModel.bills
        
        // Filtre par catégorie
        if let categoryId = selectedCategoryId {
            bills = bills.filter { $0.bill.categoryId == categoryId }
        }
        
        // Filtre par montant minimum
        if let minDecimal = Decimal(string: minAmount), !minAmount.isEmpty {
            bills = bills.filter { $0.bill.amount >= minDecimal }
        }
        
        // Filtre par montant maximum
        if let maxDecimal = Decimal(string: maxAmount), !maxAmount.isEmpty {
            bills = bills.filter { $0.bill.amount <= maxDecimal }
        }
        
        return bills
    }
    
    // Compte le nombre de filtres actifs
    private var activeFiltersCount: Int {
        var count = 0
        if selectedCategoryId != nil { count += 1 }
        if !minAmount.isEmpty { count += 1 }
        if !maxAmount.isEmpty { count += 1 }
        return count
    }
    
    init(year: Int) {
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header avec titre et bouton "+"
            HStack {
                HStack(spacing: 8) {
                    Text("Toutes les factures")
                        .font(.largeTitle)
                    
                    Picker("Année", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Spacer()
                
                // Bouton pour afficher/masquer les filtres
                Button {
                    withAnimation {
                        showFilters.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        if activeFiltersCount > 0 {
                            Text("\(activeFiltersCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .font(.title2)
                    .foregroundColor(activeFiltersCount > 0 ? .blue : .primary)
                }
                
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
            
            // Section filtres (dépliable)
            if showFilters {
                VStack(alignment: .leading, spacing: 12) {
                    
                    Divider()
                    
                    Text("Filtres")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Filtre par catégorie
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Catégorie")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.categories.isEmpty {
                            Text("Chargement des catégories...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            Picker("Catégorie", selection: $selectedCategoryId) {
                                Text("Toutes les catégories").tag(nil as Int?)
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
                    .padding(.horizontal)
                    
                    // Filtres par montant
                    HStack(spacing: 16){
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Montant min")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $minAmount)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Montant max")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $maxAmount)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bouton pour réinitialiser les filtres
                    if activeFiltersCount > 0 {
                        Button {
                            selectedCategoryId = nil
                            minAmount = ""
                            maxAmount = ""
                        } label: {
                            Text("Réinitialiser les filtres")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                }
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if viewModel.isLoading {
                ProgressView("Chargement des factures…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if let error = viewModel.errorMessage {
                ErrorView(
                    message: error,
                    retryAction: {
                        Task { await viewModel.loadBills(year: selectedYear) }
                    }
                )
            }
            else if viewModel.bills.isEmpty {
                if activeFiltersCount > 0 {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Aucun résultat",
                        message: "Aucune facture ne correspond à tes critères de recherche.",
                        actionTitle: "Réinitialiser les filtres",
                        action: {
                            selectedCategoryId = nil
                            minAmount = ""
                            maxAmount = ""
                        }
                    )
                } else {
                    EmptyStateView(
                        title: "Aucune facture",
                        message: "Tu n'as pas encore de facture enregistrée pour \(selectedYear).",
                        actionTitle: "Ajouter une facture",
                        action: {
                            showCreateForm = true
                        }
                    )
                }
            }
            else {
                List(filteredBills) { bill in
                    NavigationLink(value: bill.bill) {
                        BillRowView(
                            bill: bill.bill,
                            categoryColor: bill.categoryColor ?? "#999999", // Couleur par défaut
                            onEdit: {
                                billToEdit = bill.bill
                            },
                            onDelete: {
                                billToDelete = bill.bill
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .task {
            await viewModel.loadBills(year: selectedYear)
        }
        .onChange(of: selectedYear) { oldYear, newYear in
            print("📅 Année changée (All Bills): \(oldYear) → \(newYear)")
            Task {
                await viewModel.loadBills(year: newYear)
            }
        }
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            BillFormView() { newBill in
                let categoryColor = viewModel.categoryColor(for: newBill.categoryId)
                viewModel.bills.append(BillWithCategory(bill: newBill, categoryColor: categoryColor))
            }
        }
        .sheet(item: $billToEdit) { bill in
            BillFormView(bill: bill) { updatedBill in
                if let index = viewModel.bills.firstIndex(where: { $0.id == updatedBill.id }) {
                    let categoryColor = viewModel.categoryColor(for: updatedBill.categoryId)
                    viewModel.bills[index] = BillWithCategory(bill: updatedBill, categoryColor: categoryColor)
                }
            }
        }
        .alert("Supprimer cette facture ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                if let bill = billToDelete {
                    Task {
                        await deleteBill(bill)
                    }
                }
            }
            Button("Annuler", role: .cancel) {
                billToDelete = nil
            }
        } message: {
            if let bill = billToDelete {
                Text("Es-tu sûr de vouloir supprimer la facture '\(bill.title)'?")
            }
        }
    }
    
    private func deleteBill(_ bill: Bill) async {
        await viewModel.deleteBill(billId: bill.id)
        billToDelete = nil
    }
}
