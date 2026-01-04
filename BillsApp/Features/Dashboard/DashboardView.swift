//
//  DashboardView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()
    @State private var displayMode: DisplayMode = .pie
    @State private var selectedCategory: DashboardCategoryStats?

    enum DisplayMode {
        case pie
        case bar
    }

    let token: String

    var body: some View {
        NavigationStack {
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

//                        List(dashboard.byCategory, id: \.id) { category in
//                            HStack {
//                                Text(category.categoryName)
//                                Spacer()
//                                Text(category.totalAmountFormatted)
//                            }
//                        }

                        Picker("Display mode", selection: $displayMode) {
                            Text("Camembert").tag(DisplayMode.pie)
                            Text("Barres").tag(DisplayMode.bar)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        if displayMode == .pie {
                            CategoryPieChartView(
                                categories: dashboard.byCategory,
                                onCategorySelected: { category in
                                    print("🎯 Callback appelé pour: \(category.categoryName)")
                                    selectedCategory = category
                                }
                            )
                        } else {
                            CategoryBarChartView(
                                categories: dashboard.byCategory,
                                onCategorySelected: { category in
                                    print("🎯 Callback appelé pour: \(category.categoryName)")
                                    selectedCategory = category
                                }
                            )
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
            .navigationDestination(item: $selectedCategory) { category in
                BillsListView(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    token: token,
                    year: viewModel.dashboard?.year ?? Calendar.current.component(.year, from: Date())
                )
            }
            .onChange(of: selectedCategory) { _, newValue in
                print("Selected:", newValue?.categoryName ?? "nil")
            }
        }
    }
}

