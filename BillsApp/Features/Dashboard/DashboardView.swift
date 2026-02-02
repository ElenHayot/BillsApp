//
//  DashboardView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var navigationPath: NavigationPath
    
    @State private var displayMode: DisplayMode = .pie
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    @State private var showCamera = false
    #if os(iOS)
    @State private var capturedImage: UIImage?
    #endif
    @State private var showScanProcessing = false
    
    enum DisplayMode {
        case pie
        case bar
    }
    
    // Generate year default list
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed() // De currentYear à currentYear-9
    }

    var body: some View {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Chargement du dashboard...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
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
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        }
                        else if let dashboard = viewModel.dashboard {
                            VStack(spacing: 24) {
                                // Header Card
//                                headerCard
//                                    .padding(.horizontal)
                                
                                // Stats Overview
                                statsOverview(dashboard: dashboard)
                                    .padding(.horizontal)
                                
                                // Chart Section
                                chartSection
                                    .padding(.horizontal)
                                
                                // Quick Actions
                                quickActions
                                    .padding(.horizontal)
                                
                                // Padding to avoid the floating button to hide the content
                                Color.clear
                                    .frame(height: 100)
                            }
                            .padding(.top, 8)
                        }
                        else {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Pas de données")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        }
                    }
                }
                .background(Color.systemGroupedBackground)
                
                #if os(iOS)
                // Floating scan button
                VStack {
                    Spacer()
                    floatingScanButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34) // Safe area bottom + padding
                }
                #endif
            }
            .task {
                await viewModel.loadDashboard(year: selectedYear)
            }
            .onChange(of: selectedYear) { oldYear, newYear in
                Task {
                    await viewModel.loadDashboard(year: newYear)
                }
            }
            .onChange(of: navigationPath) { oldPath, newPath in
                if oldPath.count > 0 && newPath.isEmpty {
                    Task {
                        await viewModel.loadDashboard(year: selectedYear)
                    }
                }
            }
            #if os(iOS)
            // Sheet for camera
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera)
            }
            // Sheet for image treatment
            .sheet(item: $capturedImage) { image in
                ScanProcessingView(image: image) {
                    // Callback after image treatment
                    Task {
                        await viewModel.loadDashboard(year: selectedYear)
                    }
                }
            }
            #endif
//        }
    }
    
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Stats Overview
    
    private func statsOverview(dashboard: DashboardResponse) -> some View {
        HStack(spacing: 16) {
            // Total Amount Card
            VStack(spacing: 8) {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(dashboard.globalStats.totalAmountFormatted)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            // Number of Bills Card
            VStack(spacing: 8) {
                Text("Factures")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text("\(dashboard.globalStats.nbBills)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(spacing: 16) {
            // Chart Type Picker
            HStack {
                Text("Visualisation")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Display mode", selection: $displayMode) {
                    Image(systemName: "chart.pie")
                        .tag(DisplayMode.pie)
                    Image(systemName: "chart.bar")
                        .tag(DisplayMode.bar)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            
            // Chart Container
            VStack(spacing: 16) {
                HStack {
                    Text("Répartition par catégorie")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Année", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .foregroundColor(.primary)
                }
                
                // Chart content
                if let dashboard = viewModel.dashboard {
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Actions rapides")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // All bills navigate
                Button {
                    navigationPath.append("all-bills")
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Factures")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                // Categories navigate
                Button {
                    navigationPath.append("categories")
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Catégories")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                // Providers navigate
                Button {
                    navigationPath.append("providers")
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Fournisseurs")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Floating Scan Button
    
    private var floatingScanButton: some View {
        Button {
            #if os(iOS)
            showCamera = true
            #else
            // On macOS, should be a file picker option
            print("Scan non disponible sur macOS")
            #endif
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanner une facture")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#if os(iOS)
// Extension to set UIImage as identifiable (requisite for .sheet(item:))
extension UIImage: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}
#endif
