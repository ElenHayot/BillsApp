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
        }
        .padding(.vertical, 4)
    }
}
