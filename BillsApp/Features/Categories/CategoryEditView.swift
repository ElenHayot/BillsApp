//
//  CategoryEditView.swift
//  BillsApp
//
//  Created by Elen Hayot on 10/01/2026.
//

import SwiftUI

struct CategoryEditView: View {
    let category: Category
    let onUpdated: (Category) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CategoryEditViewModel()
    
    @State private var name: String
    @State private var selectedColor: String
    @State private var showColorPicker = false
    
    // Liste de couleurs prédéfinies
    private let availableColors = [
        "#FF5733", "#33FF57", "#3357FF", "#FF33F5",
        "#F5FF33", "#33FFF5", "#FF8C33", "#8C33FF",
        "#33FF8C", "#FF3333", "#33FFFF", "#FFFF33",
        "#9B59B6", "#3498DB", "#E74C3C", "#2ECC71",
        "#F39C12", "#1ABC9C", "#34495E", "#95A5A6"
    ]
    
    init(category: Category, onUpdated: @escaping (Category) -> Void){
        self.category = category
        self.onUpdated = onUpdated
        
        // Initialise les states avec les valeurs actuelles
        _name = State(initialValue: category.name)
        _selectedColor = State(initialValue: category.color)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Category")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Champ nom
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                
                TextField("Category name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)
            }
            
            // Champ couleur
            VStack(alignment: .leading, spacing: 8){
                Text("Color")
                    .font(.headline)
                
                HStack {
                    // Aperçu de la couleur sélectionnée
                    Circle()
                        .fill(Color(hex: selectedColor))
                        .frame(width: 40, height: 40)
                    
                    Text(selectedColor)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Bouton pour ouvrir le color picker
                    Button {
                        showColorPicker.toggle()
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 4)
                
                // Grid de couleurs
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
                                    selectedColor = color
                                    showColorPicker = false
                                }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            Spacer()
            
            // Boutons d'action
            HStack(spacing: 16) {
                Button("Cancel"){
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button {
                    Task { await updateCategory() }
                } label: {
                    if viewModel.isUpdating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || viewModel.isUpdating)
                
            }
        }
        .padding()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)){
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func updateCategory() async {
        let updatedCategory = await viewModel.updateCategory(
            categoryName: category.name,
            name: name,
            color: selectedColor
        )
        
        if let updatedCategory {
            onUpdated(updatedCategory)
            dismiss()
        }
    }
}
