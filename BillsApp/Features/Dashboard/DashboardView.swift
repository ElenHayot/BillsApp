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
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Dashboard \(dashboard.year)")
                                    .font(.title)
                                
                                Text("Total: \(dashboard.globalStats.totalAmountFormatted)")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            // ✅ Bouton pour accéder aux catégories
                            Button {
                                navigationPath.append("categories")
                            } label: {
                                Image(systemName: "tag.fill")
                                    .font(.title2)
                            }
                        }

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
            .navigationDestination(for: String.self) { destination in
                if destination == "categories" {
                    CategoriesListView(token: token)
                }
            }
        }
    }
}
