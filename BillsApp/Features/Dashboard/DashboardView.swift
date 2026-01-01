//
//  DashboardView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()
    let token: String

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading dashboard...")
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            else if let dashboard = viewModel.dashboard {

                VStack(alignment: .leading, spacing: 16) {

                    Text("Dashboard \(dashboard.year)")
                        .font(.title)

                    Text("Total: \(dashboard.globalStats.totalAmountFormatted)")
                        .font(.headline)

                    List(dashboard.byCategory, id: \.id) { category in
                        HStack {
                            Text(category.categoryName)
                            Spacer()
                            Text(category.totalAmountFormatted.description)
                        }
                    }
                }
            }
            else {
                Text("No data")
            }
        }
        .padding()
        .task {
            await viewModel.loadDashboard(token: token)
        }
    }
}

