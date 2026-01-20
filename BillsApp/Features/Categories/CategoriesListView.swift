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
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            headerView
            
            // Contenu
            contentView
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
    
    // MARK: - subviews
    
    private var headerView: some View {
        // Header avec titre et bouton "+"
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Categories")
                    .font(.largeTitle)
            }
            Spacer()
            
            Button {
                showCreateForm = true
            } label: {
                Image(systemName: "plus.circle.fill")
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
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("Loading categories…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        else if let error = viewModel.errorMessage {
            ErrorView(
                message: error,
                retryAction: {
                    Task { await viewModel.loadCategories() }
                }
            )
        }
        else if viewModel.categories.isEmpty {
            EmptyStateView(
                icon: "tag.slash",
                title: "Aucune catégorie",
                message: "Commence par créer au moins une catégorie pour organiser tes factures.",
                actionTitle: "Créer une catégorie",
                action: { showCreateForm = true }
            )
        }
        else {
            List(viewModel.categories) { category in
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
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
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
