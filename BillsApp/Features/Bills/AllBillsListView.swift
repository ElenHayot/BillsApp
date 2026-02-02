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
    
    // Filtered bills
    private var filteredBills: [BillWithCategory] {
        var bills = viewModel.bills
        
        // Filtered by category
        if let categoryId = selectedCategoryId {
            bills = bills.filter { $0.bill.categoryId == categoryId }
        }
        
        // Filtered by min amount
        if let minDecimal = Decimal(string: minAmount), !minAmount.isEmpty {
            bills = bills.filter { $0.bill.amount >= minDecimal }
        }
        
        // Filtered by max amount
        if let maxDecimal = Decimal(string: maxAmount), !maxAmount.isEmpty {
            bills = bills.filter { $0.bill.amount <= maxDecimal }
        }
        
        return bills
    }
    
    // Number of active filters
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
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if showFilters {
                        filtersCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    contentView
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .background(Color.systemGroupedBackground)
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
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Toutes les factures")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Text("Année")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Année", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text("\(year)").tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Filter button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFilters.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                            if activeFiltersCount > 0 {
                                Text("\(activeFiltersCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(activeFiltersCount > 0 ? .blue : .secondary)
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    
                    // Create button
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Filters Card
    
    private var filtersCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Filtres")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if activeFiltersCount > 0 {
                    Button {
                        selectedCategoryId = nil
                        minAmount = ""
                        maxAmount = ""
                    } label: {
                        Text("Réinitialiser")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(spacing: 16) {
                // Filtered by category
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
                
                // Filtered by amount
                #if os(iOS)
                VStack(spacing: 16) {
                    amountFilterField(title: "Montant min", text: $minAmount)
                    amountFilterField(title: "Montant max", text: $maxAmount)
                }
                #else
                HStack(spacing: 16) {
                    amountFilterField(title: "Montant min", text: $minAmount)
                    amountFilterField(title: "Montant max", text: $maxAmount)
                }
                #endif
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Chargement des factures...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if let error = viewModel.errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.body)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Réessayer") {
                    Task { await viewModel.loadBills(year: selectedYear) }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if viewModel.bills.isEmpty {
            if activeFiltersCount > 0 {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Aucun résultat")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Aucune facture ne correspond à tes critères de recherche.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Réinitialiser les filtres") {
                        selectedCategoryId = nil
                        minAmount = ""
                        maxAmount = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Aucune facture")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tu n'as pas encore de facture enregistrée pour \(selectedYear).")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Ajouter une facture") {
                        showCreateForm = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            }
        }
        else {
            VStack(spacing: 0) {
                ForEach(filteredBills) { bill in
                    NavigationLink(value: bill.bill) {
                        BillRowView(
                            bill: bill.bill,
                            categoryColor: bill.categoryColor ?? "#999999",
                            onEdit: {
                                billToEdit = bill.bill
                            },
                            onDelete: {
                                billToDelete = bill.bill
                                showDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    
                    if bill.bill.id != filteredBills.last?.bill.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    
    // MARK: - helpers
    
    private func deleteBill(_ bill: Bill) async {
        await viewModel.deleteBill(billId: bill.id)
        billToDelete = nil
    }
    
    private func amountFilterField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("0.00", text: text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                #else
                .textFieldStyle(.roundedBorder)
                #endif
        }
    }
}
