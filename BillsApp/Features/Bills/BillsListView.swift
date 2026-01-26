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
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Section filtres (dépliable)
                    if showFilters {
                        filtersCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    // Contenu
                    contentView
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
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
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: categoryColor))
                            .frame(width: 16, height: 16)
                        
                        Text(categoryName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
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
                    // Bouton filtres
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
                    
                    // Bouton créer
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
            .background(Color(UIColor.systemBackground))
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
            
            // Filtres par montant
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
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
                    Task { await viewModel.loadBills(categoryId: categoryId, year: selectedYear) }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if filteredBills.isEmpty {
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
                    Text("Tu n'as encore aucune facture dans \(categoryName) pour \(selectedYear).")
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
        } else {
            VStack(spacing: 0) {
                ForEach(filteredBills) { bill in
                    NavigationLink(value: bill) {
                        BillRowView(
                            bill: bill,
                            categoryColor: categoryColor,
                            onEdit: { billToEdit = bill },
                            onDelete: {
                                billToDelete = bill
                                showDeleteConfirmation = true
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    
                    if bill.id != filteredBills.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - helpers
    
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
