//
//  CategoryRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoryRowView: View {
    
    let category: Category
    let token: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Pastille de couleur
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 24, height: 24)
            
            Text(category.name)
                .font(.headline)
            
            Spacer()
            
            // Bouton éditer
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            // Bouton supprimer
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}
