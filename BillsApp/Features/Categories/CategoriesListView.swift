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
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Contenu
                    contentView
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .task {
            await viewModel.loadCategories()
        }
        .sheet(isPresented: $showCreateForm) {
            CategoryFormView() { newCategory in
                // Ajoute la nouvelle catégorie à la liste
                viewModel.categories.append(newCategory)
            }
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryFormView(
                category: category
            ) { updatedCategory in
                // Met à jour la catégorie dans la liste
                if let index = viewModel.categories.firstIndex(where: { $0.id == updatedCategory.id }) {
                    viewModel.categories[index] = updatedCategory
                }
            }
        }
        .alert("Delete this category?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    Task {
                        await deleteCategory(category)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete '\(category.name)'? This action cannot be undone.")
            }
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
            .background(Color(UIColor.systemBackground))
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
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - helpers
    
    private func deleteCategory(_ category: Category) async {
        await viewModel.deleteCategory(
            category: category
        )
        // Supprime de la liste locale
        categoryToDelete = nil
    }
}
