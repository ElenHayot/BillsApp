//
//  CategoryRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoryRowView: View {
    
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Pastille de couleur
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // Contenu principal
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Couleur: \(category.color)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
