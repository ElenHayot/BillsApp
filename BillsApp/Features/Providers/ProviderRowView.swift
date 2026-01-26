//
//  ProviderRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import SwiftUI

struct ProviderRowView: View {

    let provider: Provider
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône fournisseur
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Contenu principal
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("ID: \(provider.id)")
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
