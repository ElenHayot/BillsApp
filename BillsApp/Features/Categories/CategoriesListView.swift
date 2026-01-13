//
//  CategoriesListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoriesListView: View {
    
    let token: String
    
    @StateObject private var viewModel = CategoriesViewModel()
    @State private var showCreateForm = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header avec titre et bouton "+"
            HStack {
                Text("Categories")
                    .font(.largeTitle)
                
                Spacer()
                
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)
            
            if viewModel.isLoading {
                ProgressView("Loading categories…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        token: token,
                        onEdit: {
                            categoryToEdit = category
                        },
                        onDelete: {
                            categoryToDelete = category
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadCategories(token: token)
        }
        .sheet(isPresented: $showCreateForm) {
            CategoryFormView(token: token) { newCategory in
                // Ajoute la nouvelle catégorie à la liste
                viewModel.categories.append(newCategory)
            }
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditView(
                category: category,
                token: token
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
    
    private func deleteCategory(_ category: Category) async {
        do {
            try await CategoriesService.shared.deleteCategory(
                token: token,
                categoryId: category.id,
                categoryName: category.name
            )
            // Supprime de la liste locale
            viewModel.categories.removeAll { $0.id == category.id }
            categoryToDelete = nil
        } catch {
            viewModel.errorMessage = "Failed to delete category: \(error.localizedDescription)"
        }
    }
}
