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

    // 📸 États pour le scan de facture
    @State private var showCamera = false
    #if os(iOS)
    @State private var capturedImage: UIImage?
    #endif
    @State private var showScanProcessing = false
    
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
                    ProgressView("Chargement du dashboard...")
                }
                else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                else if let dashboard = viewModel.dashboard {

                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        headerView
                        
                        // Picker mode d'affichage
                        displayModePicker

                        if displayMode == .pie {
                            CategoryPieChartView(
                                categories: dashboard.byCategory,
                                onCategorySelected: { category in
                                    navigationPath.append(category)
                                }
                            )
                        } else {
                            CategoryBarChartView(
                                categories: dashboard.byCategory,
                                onCategorySelected: { category in
                                    navigationPath.append(category)
                                }
                            )
                        }
                        
                        scanButton
                    }
                }
                else {
                    Text("Pas de données")
                }
            }
            .padding()
            .task {
                await viewModel.loadDashboard(year: selectedYear)
            }
            .onChange(of: selectedYear) { oldYear, newYear in
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
            #if os(iOS)
            // 📸 Sheet pour la caméra
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
            }
            // 📸 Sheet pour le traitement de l'image
            .sheet(item: $capturedImage) { image in
                ScanProcessingView(image: image) {
                    // Callback après traitement réussi
                    Task {
                        await viewModel.loadDashboard(year: selectedYear)
                    }
                }
            }
            #endif
            .navigationDestination(for: DashboardCategoryStats.self) { category in
                BillsListView(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    categoryColor: category.categoryColor,
                    year: selectedYear
                )
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "categories" {
                    CategoriesListView()
                } else if destination == "all-bills" {
                    AllBillsListView(
                        year: selectedYear // ✅ Utilise l'année sélectionnée
                    )
                } else if destination == "providers" {
                    ProvidersListView()
                }
            }
            // 🎯 TOOLBAR ADAPTÉ PAR PLATEFORME
            .toolbar {
                #if os(iOS)
                // iOS : bouton déconnexion en haut à droite
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                #else
                // macOS : bouton déconnexion avec label
                ToolbarItem(placement: .automatic) {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Déconnexion", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                #endif
            }
            .confirmationDialog(
                "Voulez-vous vraiment vous déconnecter ?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Se déconnecter", role: .destructive) {
                    authViewModel.logout()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }
    
    
    // MARK: - subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text("Dashboard")
                        .font(.title)
                    
                    Picker("Année", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.menu) // iOS : menu contextuel
                    #else
                    .pickerStyle(.menu) // macOS : dropdown
                    #endif
                    .labelsHidden()
                }
                
                if let dashboard = viewModel.dashboard {
                    Text("Total: \(dashboard.globalStats.totalAmountFormatted)")
                        .font(.headline)
                }
            }
            
            Spacer()
            
            // BOUTONS D'ACTION
            actionButtons
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Bouton toutes les bills
            Button {
                navigationPath.append("all-bills")
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    #if os(iOS)
                    .font(.title2)
                    .frame(width: 44, height: 44) // Zone tactile iOS
                    #else
                    .font(.title2)
                    #endif
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #endif
            
            // Bouton catégories
            Button {
                navigationPath.append("categories")
            } label: {
                Image(systemName: "tag.fill")
                    #if os(iOS)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    #else
                    .font(.title2)
                    #endif
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #endif
            
            // Bouton fournisseurs
            Button {
                navigationPath.append("providers")
            } label: {
                Image(systemName: "building.2")
                    #if os(iOS)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    #else
                    .font(.title2)
                    #endif
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #endif
        }
    }
        
    private var displayModePicker: some View {
        Picker("Display mode", selection: $displayMode) {
            Text("Camembert").tag(DisplayMode.pie)
            Text("Barres").tag(DisplayMode.bar)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // 📸 BOUTON DE SCAN - Design engageant
    private var scanButton: some View {
        Button {
            #if os(iOS)
            showCamera = true
            #else
            // Sur macOS, on pourrait proposer un file picker
            print("Scan non disponible sur macOS")
            #endif
        } label: {
            HStack {
                Image(systemName: "doc.text.viewfinder")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scanner une facture")
                        .font(.headline)
                    Text("Extraction automatique des données")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "camera.fill")
                    .font(.title3)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#if os(iOS)
// 📸 Extension pour rendre UIImage identifiable (nécessaire pour .sheet(item:))
extension UIImage: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}
#endif
