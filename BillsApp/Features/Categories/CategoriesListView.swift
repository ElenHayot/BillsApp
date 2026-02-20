//
//  CategoriesListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoriesListView: View {
    
    @StateObject private var viewModel = CategoriesViewModel()
    @State private var showCreateForm = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false
    @State var year: Int
    @State var showToast: Bool = false
    @State var toastMessage: String = ""
    
    init(year: Int) {
        self.year = year
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content
                    contentView
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .background(Color.systemGroupedBackground)
            
            if showToast {
                VStack {
                    Text(toastMessage)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)  // ← Assure it's over all
            }
        }
        .task {
            await viewModel.loadCategories()
        }
        .sheet(isPresented: $showCreateForm) {
            CategoryFormView(
                onSaved: {newCategory in
                    viewModel.categories.append(newCategory)
                },
                onSuccess: { _message in
                    showSuccessToast(_message ?? "")
                }
            )
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryFormView(
                category: category,
                onSaved: {
                    updatedCategory in
                        if let index = viewModel.categories.firstIndex(where: { $0.id == updatedCategory.id }) {
                            viewModel.categories[index] = updatedCategory
                        }
                },
                onSuccess: { message in
                    showSuccessToast(message ?? "")
                }
            )
        }
        .alert("Supprimer cette catégorie ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                if let category = categoryToDelete {
                    Task {
                        await deleteCategory(category)
                    }
                }
            }
            Button("Annuler", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let category = categoryToDelete {
                Text("Êtes-vous sûr de vouloir supprimer la catégorie '\(category.name)'? Cette action est irrévocable.")
            }
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Catégories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Organise tes factures par catégories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Chargement des catégories...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
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
                Button("Réessayer") {
                    Task { await viewModel.loadCategories() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else if viewModel.categories.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tag.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Aucune catégorie")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Commence par créer au moins une catégorie pour organiser tes factures.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Créer une catégorie") {
                    showCreateForm = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
        else {
            VStack(spacing: 0) {
                ForEach(viewModel.categories) { category in
                    CategoryRowView(
                        category: category,
                        onEdit: {
                            categoryToEdit = category
                        },
                        onDelete: {
                            categoryToDelete = category
                            showDeleteConfirmation = true
                        }
                    )
                    
                    if category.id != viewModel.categories.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - helpers
    
    private func deleteCategory(_ category: Category) async {
        do {
            try await viewModel.deleteCategory(
                category: category
            )
            categoryToDelete = nil
        } catch {}
    }
    
    /// Show toast on success message received
    private func showSuccessToast(_ message: String) {
        Task { @MainActor in
            // Sleep to let last UI called close
            try? await Task.sleep(nanoseconds: 100_000_000)
            toastMessage = message
            withAnimation {
                showToast = true
            }
            
            // sleep instead of async call
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                showToast = false
            }
        }
    }
}
