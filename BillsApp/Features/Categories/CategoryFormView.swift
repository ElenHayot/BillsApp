//
//  CategoryFormView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoryFormView: View {
    
    let category: Category? // nil = creating, non-nil = editing
    let onSaved: (Category) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CategoryFormViewModel()
    
    @State private var name = ""
    @State private var selectedColor = "#FF5733"
    @State private var showColorPicker = false
    
    @FocusState private var focusedField: Field?    // IOS focus
    
    enum Field {
        case name
    }
    
    // Predefined color list
    private let availableColors = [
        "#FF5733", "#33FF57", "#3357FF", "#FF33F5",
        "#F5FF33", "#33FFF5", "#FF8C33", "#8C33FF",
        "#33FF8C", "#FF3333", "#33FFFF", "#FFFF33",
        "#9B59B6", "#3498DB", "#E74C3C", "#2ECC71",
        "#F39C12", "#1ABC9C", "#34495E", "#95A5A6"
    ]
    
    init(category: Category? = nil, onSaved: @escaping (Category) -> Void) {
        self.category = category
        self.onSaved = onSaved
        
        _name = State(initialValue: category?.name ?? "")
        _selectedColor = State(initialValue: category != nil ? "\(category!.color)" : "")
    }
    
    var isEditing: Bool{
        category != nil
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header Card
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Form
                    formCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Actions
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.systemGroupedBackground)
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .padding()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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
                    Text(isEditing ? "Éditer la catégorie" : "Nouvelle catégorie")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if isEditing {
                        Text("Modifie la couleur et le nom de la catégorie")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Crée une nouvelle catégorie pour organiser tes factures")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: 20) {
            // Coulor
            VStack(alignment: .leading, spacing: 8) {
                Text("Couleur")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: selectedColor))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(selectedColor)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showColorPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
                                .font(.title3)
                            Text(showColorPicker ? "Masquer" : "Choisir")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                // Color grid
                if showColorPicker {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 50))
                    ], spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == color ? Color.primary : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedColor = color
                                        showColorPicker = false
                                    }
                                }
                        }
                    }
                    .padding(.top, 12)
                }
            }
            
            // Name
            formField(
                title: "Nom",
                placeholder: "Nom de la catégorie",
                text: $name,
                field: .name
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        HStack(spacing: 16) {
            Button("Annuler") {
                dismiss()
            }
            .foregroundColor(.blue)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .buttonStyle(.plain)
            
            Button {
                Task {
                    await saveCategory()
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isEditing ? "square.and.arrow.down" : "plus")
                            .font(.title3)
                    }
                    
                    Text(isEditing ? "Sauvegarder" : "Créer")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isFormValid ? [Color.blue, Color.blue.opacity(0.85)] : [Color.gray, Color.gray.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || viewModel.isSaving)
        }
    }
    
    // MARK: - helpers
    
    private func formField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                #if os(iOS)
                .focused($focusedField, equals: field)
                .autocapitalization(.words)
                #endif
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.textFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !selectedColor.isEmpty
    }
    
    private func saveCategory() async {
        let color = selectedColor
        let savedCategory: Category?
        
        if let existingCategory = category {
            // Editing
            savedCategory = await viewModel.updateCategory(
                categoryId: existingCategory.id,
                name: name,
                color: color
            )
        } else {
            // Creating
            savedCategory = await viewModel.createCategory(name: name, color: color)
        }
        
        if let savedCategory = savedCategory {
            onSaved(savedCategory)
            dismiss()
        }
    }
}
