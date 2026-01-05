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
//    @State private var selectedCategory: DashboardCategoryStats?
    @State private var navigationPath = NavigationPath()

    enum DisplayMode {
        case pie
        case bar
    }

    let token: String

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                    navigationPath.append(category)
                                }
                            )
                        } else {
                            CategoryBarChartView(
                                categories: dashboard.byCategory,
                                onCategorySelected: { category in
                                    print("🎯 Callback appelé pour: \(category.categoryName)")
                                    navigationPath.append(category)
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
            .navigationDestination(for: DashboardCategoryStats.self) { category in
                BillsListView(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    categoryColor: category.categoryColor,
                    token: token,
                    year: viewModel.dashboard?.year ?? Calendar.current.component(.year, from: Date())
                )
            }
            .navigationDestination(for: Bill.self) { bill in
                BillDetailView(bill: bill, token: token)
            }
//            .onChange(of: selectedCategory) { _, newValue in
//                print("Selected:", newValue?.categoryName ?? "nil")
//            }
        }
    }
}

