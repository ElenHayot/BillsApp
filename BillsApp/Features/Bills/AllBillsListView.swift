//
//  AllBillsListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct AllBillsListView: View {
    
    let token: String
    @State private var selectedYear: Int
    
    @StateObject private var viewModel = AllBillsListViewModel()
    @State private var showCreateForm = false
    @State private var billToEdit: Bill?
    @State private var billToDelete: Bill?
    @State private var showDeleteConfirmation = false
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    init(token: String, year: Int) {
        self.token = token
        _selectedYear = State(initialValue: year)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header avec titre et bouton "+"
            HStack {
                HStack(spacing: 8) {
                    Text("All Bills")
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            await viewModel.loadBills(token: token, year: selectedYear)
        }
        .onChange(of: selectedYear) { oldYear, newYear in
            print("📅 Année changée (All Bills): \(oldYear) → \(newYear)")
            Task {
                await viewModel.loadBills(token: token, year: newYear)
            }
        }
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill, token: token)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreateForm) {
            BillFormView(token: token) { newBill in
                let categoryColor = viewModel.categoryColor(for: newBill.categoryId)
                viewModel.bills.append(BillWithCategory(bill: newBill, categoryColor: categoryColor))
            }
        }
        .sheet(item: $billToEdit) { bill in
            BillFormView(token: token, bill: bill) { updatedBill in
                if let index = viewModel.bills.firstIndex(where: { $0.id == updatedBill.id }) {
                    let categoryColor = viewModel.categoryColor(for: updatedBill.categoryId)
                    viewModel.bills[index] = BillWithCategory(bill: updatedBill, categoryColor: categoryColor)
                }
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
    
    private func deleteBill(_ bill: Bill) async {
        do {
            try await BillsService.shared.deleteBill(
                token: token,
                billId: bill.id
            )
            viewModel.bills.removeAll { $0.id == bill.id }
            billToDelete = nil
        } catch {
            viewModel.errorMessage = "Failed to delete bill: \(error.localizedDescription)"
        }
    }
}
