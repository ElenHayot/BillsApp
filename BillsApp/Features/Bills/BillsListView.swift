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
    let year: Int

    @StateObject private var viewModel = BillsListViewModel()

    var body: some View {
        VStack(alignment: .leading) {

            Text(categoryName)
                .font(.largeTitle)
                .padding(.bottom, 8)

            if viewModel.isLoading {
                ProgressView("Loading bills…")
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            else if viewModel.bills.isEmpty {
                Text("No bills for this category")
                    .foregroundColor(.secondary)
            }
            else {
                List(viewModel.bills) { bill in
                    NavigationLink(value: bill) {
                        BillRowView(
                            bill: bill,
                            categoryColor: categoryColor
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
                year: year
            )
        }
        // ✅ Passe le viewModel comme EnvironmentObject
        .navigationDestination(for: Bill.self) { bill in
            BillDetailView(bill: bill, token: token)
                .environmentObject(viewModel)
        }
    }
}
