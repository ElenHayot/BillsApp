//
//  BillRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct BillRowView: View {

    let bill: Bill
    let categoryColor: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Pastille couleur catégorie
            Circle()
                .fill(Color(hex: categoryColor))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(bill.title)
                    .font(.headline)

                Text(bill.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(bill.amountFormatted)
                .bold()
            
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
