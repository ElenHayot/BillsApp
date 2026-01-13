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
    let token: String
    @State private var selectedYear: Int
    
    @StateObject private var viewModel = BillsListViewModel()
    @State private var showCreateForm = false
    @State private var billToEdit: Bill?
    @State private var billToDelete: Bill?
    @State private var showDeleteConfirmation = false
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    init(categoryId: Int, categoryName: String, categoryColor: String, token: String, year: Int) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryColor = categoryColor
        self.token = token
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        VStack(alignment: .leading) {
            
            // Header avec titre et bouton "+"
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                   Text(categoryName)
                       .font(.largeTitle)
                   
                   Picker("Year", selection: $selectedYear) {
                       ForEach(availableYears, id: \.self) { year in
                           Text("\(year)").tag(year)
                       }
                   }
                   .pickerStyle(.menu)
                   .labelsHidden()
               }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)


            if viewModel.isLoading {
                ProgressView("Loading bills…")
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            else if viewModel.bills.isEmpty {
                EmptyStateView(
                    title: "Aucune facture",
                    message: "Tu n’as encore aucune facture pour \(selectedYear).",
                    actionTitle: "Ajouter une facture",
                    action: {
                        showCreateForm = true
                    }
                )
            }
            else {
                List(viewModel.bills) { bill in
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
                token: token,
                categoryId: categoryId,
                year: selectedYear
            )
        }
        .onChange(of: selectedYear) { oldYear, newYear in
            print("📅 Année changée (\(categoryName)): \(oldYear) → \(newYear)")
            Task {
                await viewModel.loadBills(
                    token: token,
                    categoryId: categoryId,
                    year: newYear
                )
            }
        }
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill, token: token)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            BillFormView(
                token: token,
                defaultCategoryId: categoryId
            ) { newBill in
                handleBillCreated(newBill)
            }
        }
        .sheet(item: $billToEdit) { bill in
            BillFormView(token: token, bill: bill) { updatedBill in
                handleBillUpdated(updatedBill)
            }
        }
        .alert("Delete this bill?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let bill = billToDelete {
                    Task {
                        await deleteBill(bill)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                billToDelete = nil
            }
        } message: {
            if let bill = billToDelete {
                Text("Are you sure you want to delete '\(bill.title)'?")
            }
        }
    }
    
    // ✅ Gère la création : ajoute uniquement si c'est la bonne catégorie, sinon recharge
    private func handleBillCreated(_ newBill: Bill) {
        if newBill.categoryId == categoryId {
            // Même catégorie → ajout local
            viewModel.bills.append(newBill)
        } else {
            // Catégorie différente → recharge la liste
            Task {
                await viewModel.loadBills(
                    token: token,
                    categoryId: categoryId,
                    year: selectedYear
                )
            }
        }
    }
    
    // ✅ Gère la mise à jour : met à jour si même catégorie, sinon recharge
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
                    token: token,
                    categoryId: categoryId,
                    year: selectedYear
                )
            }
        }
    }
    
    private func deleteBill(_ bill: Bill) async {
        do {
            try await BillsService.shared.deleteBill(
                token: token,
                billId: bill.id
            )
            // Supprime de la liste locale
            viewModel.bills.removeAll { $0.id == bill.id }
            billToDelete = nil
        } catch {
            viewModel.errorMessage = "Failed to delete bill: \(error.localizedDescription)"
        }
    }
}
