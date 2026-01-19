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
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(provider.name)
                    .font(.headline)
                
                Text(String(provider.id)).font(Font.caption.italic())
            }

            Spacer()
            
            // Bouton éditer
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            // Bouton supprimer
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
