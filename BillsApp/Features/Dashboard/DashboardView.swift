//
//  DashboardView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var displayMode: DisplayMode = .pie
    @State private var navigationPath = NavigationPath()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date()) //Année actuelle par défaut

    enum DisplayMode {
        case pie
        case bar
    }
    
    // Génère une liste d'années (par exemple les 10 dernières années)
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed() // De currentYear à currentYear-9
    }


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
//                    if dashboard.byCategory.isEmpty {
//                        EmptyStateView(
//                            icon: "tag.slash",
//                            title: "Aucune catégorie",
//                            message: "Commence par créer au moins une catégorie pour organiser tes factures.",
//                            actionTitle: "Créer une catégorie",
//                            action: {
//                                navigationPath.append("categories")
//                            }
//                        )
//                    }
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack(spacing: 8) {
                                    Text("Dashboard")
                                        .font(.title)
                                    
                                    Picker("Year", selection: $selectedYear) {
                                        ForEach(availableYears, id: \.self) { year in
                                            Text("\(year)").tag(year)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                }
                                
                                Text("Total: \(dashboard.globalStats.totalAmountFormatted)")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            // ✅ Bouton pour voir toutes les bills
                            Button {
                                navigationPath.append("all-bills")
                            } label: {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.title2)
                            }
                            
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
                        .toolbar {
                            ToolbarItem() {
                                Button {
                                    showLogoutConfirmation = true
                                } label: {
                                    Label("Déconnexion", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        }
                        .confirmationDialog(
                            "Voulez-vous vraiment vous déconnecter ?",
                            isPresented: $showLogoutConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Se déconnecter", role: .destructive) {
                                authViewModel.logout()
                                // ✨ Pas besoin de navigation manuelle !
                                // isAuthenticated = false va automatiquement
                                // afficher LoginView dans RootView
                            }
                            
                            Button("Annuler", role: .cancel) {}
                        }

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
                await viewModel.loadDashboard(year: selectedYear)
            }
            .onChange(of: selectedYear) { oldYear, newYear in
                print("📅 Année changée: \(oldYear) → \(newYear)")
                Task {
                    await viewModel.loadDashboard(year: newYear)
                }
            }
            .onChange(of: navigationPath) { oldPath, newPath in
                // Si on revient au dashboard (path devient vide)
                if oldPath.count > 0 && newPath.isEmpty {
                    Task {
                        await viewModel.loadDashboard(year: selectedYear)
                    }
                }
            }
            .navigationDestination(for: DashboardCategoryStats.self) { category in
                BillsListView(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    categoryColor: category.categoryColor,
                    year: selectedYear // ✅ Utilise l'année sélectionnée
                )
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "categories" {
                    CategoriesListView()
                } else if destination == "all-bills" {
                    AllBillsListView(
                        year: selectedYear // ✅ Utilise l'année sélectionnée
                    )
                }
            }
        }
    }
}
