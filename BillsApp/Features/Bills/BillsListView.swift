//
//  BillsListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct BillsListView: View {

    let categoryId: Int
    let categoryName: String
    let categoryColor: String
    @State private var selectedYear: Int
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var showFilters = false
    
    @StateObject private var viewModel = BillsListViewModel()
    @State private var showCreateForm = false
    @State private var billToEdit: Bill?
    @State private var billToDelete: Bill?
    @State private var showDeleteConfirmation = false
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    // Bills filtrées selon les critères
    private var filteredBills: [Bill] {
        var bills = viewModel.bills
        
        // Filtre par montant minimum
        if let minDecimal = Decimal(string: minAmount), !minAmount.isEmpty {
            bills = bills.filter { $0.amount >= minDecimal }
        }
        
        // Filtre par montant maximum
        if let maxDecimal = Decimal(string: maxAmount), !maxAmount.isEmpty {
            bills = bills.filter { $0.amount <= maxDecimal }
        }
        
        return bills
    }
    
    // Compte le nombre de filtres actifs
    private var activeFiltersCount: Int {
        var count = 0
        if !minAmount.isEmpty { count += 1 }
        if !maxAmount.isEmpty { count += 1 }
        return count
    }
    
    init(categoryId: Int, categoryName: String, categoryColor: String, year: Int) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryColor = categoryColor
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                   Text(categoryName)
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
                    
                    // Filtres par montant
                    HStack(spacing: 16) {
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
            }
            else if let error = viewModel.errorMessage {
                ErrorView(
                    message: error,
                    retryAction: {
                        Task { await viewModel.loadBills(categoryId: categoryId, year: selectedYear) }
                    }
                )
            }
            else if filteredBills.isEmpty {
               if activeFiltersCount > 0 {
                   EmptyStateView(
                       icon: "magnifyingglass",
                       title: "Aucun résultat",
                       message: "Aucune facture ne correspond à tes critères de recherche.",
                       actionTitle: "Réinitialiser les filtres",
                       action: {
                           minAmount = ""
                           maxAmount = ""
                       }
                   )
               } else {
                   EmptyStateView(
                        icon: "doc.text",
                        title: "Aucune facture",
                        message: "Tu n'as encore aucune facture dans \(categoryName) pour \(selectedYear).",
                        actionTitle: "Ajouter une facture",
                        action: {
                            showCreateForm = true
                        }
                   )
               }
            } else {
                List(filteredBills) { bill in
                    NavigationLink(value: bill) {
                        BillRowView(
                            bill: bill,
                            categoryColor: categoryColor,
                            onEdit: {
                                billToEdit = bill
                            },
                            onDelete: {
                                billToDelete = bill
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .task {
            await viewModel.loadBills(
                categoryId: categoryId,
                year: selectedYear
            )
        }
        .onChange(of: selectedYear) { oldYear, newYear in
            Task {
                await viewModel.loadBills(
                    categoryId: categoryId,
                    year: newYear
                )
            }
        }
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            BillFormView(
                defaultCategoryId: categoryId
            ) { newBill in
                handleBillCreated(newBill)
            }
        }
        .sheet(item: $billToEdit) { bill in
            BillFormView(bill: bill) { updatedBill in
                handleBillUpdated(updatedBill)
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
                Text("Es-tu sûr de vouloir supprimer la facture '\(bill.title)' ?")
            }
        }
    }
    
    // Gère la création : ajoute uniquement si c'est la bonne catégorie, sinon recharge
    private func handleBillCreated(_ newBill: Bill) {
        if newBill.categoryId == categoryId {
            // Même catégorie → ajout local
            viewModel.bills.append(newBill)
        } else {
            // Catégorie différente → recharge la liste
            Task {
                await viewModel.loadBills(
                    categoryId: categoryId,
                    year: selectedYear
                )
            }
        }
    }
    
    // Gère la mise à jour : met à jour si même catégorie, sinon recharge
    private func handleBillUpdated(_ updatedBill: Bill) {
        if updatedBill.categoryId == categoryId {
            // Même catégorie → mise à jour locale
            if let index = viewModel.bills.firstIndex(where: { $0.id == updatedBill.id }) {
                viewModel.bills[index] = updatedBill
            }
        } else {
            // Catégorie changée → recharge la liste (la bill a disparu de cette catégorie)
            Task {
                await viewModel.loadBills(
                    categoryId: categoryId,
                    year: selectedYear
                )
            }
        }
    }
    
    private func deleteBill(_ bill: Bill) async {
        await viewModel.deleteBill( billId: bill.id )
        billToDelete = nil
    }
}
