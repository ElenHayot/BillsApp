//
//  UnifiedBillsListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 13/02/2026.
//

import SwiftUI

struct UnifiedBillsListView: View {
    
    // MARK: - Parameters (optionals in "all-bills" view)
    let categoryId: Int?
    let categoryName: String?
    let categoryColor: String?
    
    // MARK: - Common states
    @State private var selectedYear: Int
    @State private var selectedCategoryId: Int? // category filter (for all-bills view)
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var showFilters = false
    
    @StateObject private var viewModel = UnifiedBillsListViewModel()
    @State private var showCreateForm = false
    @State private var billToEdit: Bill?
    @State private var billToDelete: Bill?
    @State private var showDeleteConfirmation = false
    @State private var showToast = false
    @State private var toastMessage: String = ""
    
    // MARK: - Computed Properties to manage both modes
    
    /// Determinate if its "all-bills" mode
    private var isAllBillsView: Bool {
        categoryId == nil
    }
    
    /// Title displayed in header
    private var displayTitle: String {
        isAllBillsView ? "Toutes les factures" : (categoryName ?? "")
    }
    
    /// Color to use for display
    private var displayColor: String {
        if isAllBillsView {
            return "#999999" // Default color
        }
        return categoryColor ?? "#999999"
    }
    
    /// Available picker years
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    /// Filtered invoices accorded to active mode and filters
    private var filteredBills: [BillWithCategory] {
        var bills = viewModel.bills
        
        // FILTER BY CATEGORY (only available in "all-bills" view mode)
        if isAllBillsView, let filterCategoryId = selectedCategoryId {
            bills = bills.filter { $0.bill.categoryId == filterCategoryId }
        }
        
        // FILTER BY AMOUNT
        if let minDecimal = Decimal(string: minAmount), !minAmount.isEmpty {
            bills = bills.filter { $0.bill.amount >= minDecimal }
        }
        
        if let maxDecimal = Decimal(string: maxAmount), !maxAmount.isEmpty {
            bills = bills.filter { $0.bill.amount <= maxDecimal }
        }
        
        return bills
    }
    
    /// Number of activated filters
    private var activeFiltersCount: Int {
        var count = 0
        if !isAllBillsView && selectedCategoryId != nil { count += 1 }
        if !minAmount.isEmpty { count += 1 }
        if !maxAmount.isEmpty { count += 1 }
        return count
    }
    
    // MARK: - Initializers
    
    /// Initialize "all-bills" view
    init(year: Int) {
        self.categoryId = nil
        self.categoryName = nil
        self.categoryColor = nil
        _selectedYear = State(initialValue: year)
    }
    
    /// Initialize "bills-by-category" view
    init(categoryId: Int, categoryName: String, categoryColor: String, year: Int) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryColor = categoryColor
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
            
            if showToast {
                VStack {
                    Text(toastMessage)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)  // ← Assure it's over all
            }
        }
        .task {
            await loadBills()
        }
        .task(id: selectedYear) {
            await loadBills()
        }
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill) { deletedBillId in
                viewModel.bills.removeAll { $0.id == deletedBillId }
            }
        }
        .sheet(isPresented: $showCreateForm) {
            BillFormView(
                defaultCategoryId: categoryId,
                onSaved: { updatedBill in
                    handleBillCreated(updatedBill)
                },
                onSuccess: { message in
                    showSuccessToast(message)
                }
            )
        }
        .sheet(item: $billToEdit) { bill in
            BillFormView(
                bill: bill,
                onSaved: { updatedBill in
                    handleBillUpdated(updatedBill)
                },
                onSuccess: { message in
                    showSuccessToast(message)
                }
            )
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
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                print("UnifiedBillsListView: Error")
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
                VStack(alignment: .leading, spacing: 8) {
                    // TITLE : with or without colored circle accortdint to the mode
                    HStack(spacing: 8) {
                        if !isAllBillsView {
                            // Category mode : colored circle
                            Circle()
                                .fill(Color(hex: displayColor))
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    // YEAR PICKER
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
                
                // ACTION BUTTON
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
                    
                    // Creating button
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
                        resetFilters()
                    } label: {
                        Text("Réinitialiser")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(spacing: 16) {
                // FILTER BY CATEGORY (only for all-bills view)
                if isAllBillsView {
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
                }
                
                // FILTER ON AMOUNT
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
    
    // MARK: - Content View
    
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
                    Task { await loadBills() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if viewModel.bills.isEmpty {
            if activeFiltersCount > 0 {
                // If no result with current filters
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
                        resetFilters()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // If no bill at all
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Aucune facture")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(emptyStateMessage)
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
            // All bills list
            VStack(spacing: 0) {
                ForEach(filteredBills) { billWithCategory in
                    NavigationLink(value: billWithCategory.bill) {
                        BillRowView(
                            bill: billWithCategory.bill,
                            categoryColor: billWithCategory.categoryColor ?? "#999999",
                            onEdit: {
                                billToEdit = billWithCategory.bill
                            },
                            onDelete: {
                                billToDelete = billWithCategory.bill
                                showDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    
                    if billWithCategory.bill.id != filteredBills.last?.bill.id {
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
    
    // MARK: - Helper Methods
    
    /// State message personnalized according to active mode
    private var emptyStateMessage: String {
        if isAllBillsView {
            return "Tu n'as pas encore de facture enregistrée pour \(selectedYear)."
        } else {
            return "Tu n'as encore aucune facture dans \(categoryName ?? "cette catégorie") pour \(selectedYear)."
        }
    }
    
    /// Reinitialize all filters
    private func resetFilters() {
        selectedCategoryId = nil
        minAmount = ""
        maxAmount = ""
    }
    
    /// Load active mode bills
    private func loadBills() async {
        if isAllBillsView {
            // Mode "all-bills" : load all bills without filtering
            await viewModel.loadAllBills(year: selectedYear)
        } else {
            // Mode "bill-by-category" : load all bills of one specific category
            await viewModel.loadCategoryBills(categoryId: categoryId!, year: selectedYear)
        }
    }
    
    /// Manage new bill creation
    private func handleBillCreated(_ newBill: Bill) {
        if isAllBillsView {
            // Mode "all-bills"
            let categoryColor = viewModel.categoryColor(for: newBill.categoryId)
            viewModel.bills.append(BillWithCategory(bill: newBill, categoryColor: categoryColor))
        } else {
            // Mode "bill-by-category" : check if its the same category
            if newBill.categoryId == categoryId {
                // Same category
                viewModel.bills.append(BillWithCategory(bill: newBill, categoryColor: categoryColor))
            } else {
                // Different category => reload data
                Task {
                    await loadBills()
                }
            }
        }
    }
    
    /// Manage bill update
    private func handleBillUpdated(_ updatedBill: Bill) {
        if isAllBillsView {
            // Mode "all-bills"
            if let index = viewModel.bills.firstIndex(where: { $0.id == updatedBill.id }) {
                let categoryColor = viewModel.categoryColor(for: updatedBill.categoryId)
                viewModel.bills[index] = BillWithCategory(bill: updatedBill, categoryColor: categoryColor)
            }
        } else {
            // Mode "bill-by-category"
            if updatedBill.categoryId == categoryId {
                // If same category
                if let index = viewModel.bills.firstIndex(where: { $0.id == updatedBill.id }) {
                    viewModel.bills[index] = BillWithCategory(bill: updatedBill, categoryColor: categoryColor)
                }
            } else {
                // If category changed => reload data
                Task {
                    await loadBills()
                }
            }
        }
    }
    
    /// Delete a bill
    private func deleteBill(_ bill: Bill) async {
        do {
            try await viewModel.deleteBill(billId: bill.id)
            billToDelete = nil
            
            if let message = viewModel.successMessage{
                showSuccessToast(message)
                viewModel.successMessage = nil
            }
        } catch {}
    }
    
    /// Filter on amount
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
    
    /// Show toast on success message received
    private func showSuccessToast(_ message: String) {
        Task { @MainActor in
            // Sleep to let last UI called close
            try? await Task.sleep(nanoseconds: 100_000_000)
            toastMessage = message
            withAnimation {
                showToast = true
            }
            
            // sleep instead of async call
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                showToast = false
            }
        }
    }
    
    //    private func showSuccessToast(_ message: String) {
    //        toastMessage = message
    //        withAnimation {
    //            showToast = true
    //        }
    //
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
    //            withAnimation {
    //                showToast = false
    //            }
    //        }
    //    }

}
