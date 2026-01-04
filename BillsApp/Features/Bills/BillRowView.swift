//
//  BillRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct BillRowView: View {

    let bill: Bill

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(bill.title)
                    .font(.headline)

                Text(bill.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(bill.amount, format: .currency(code: "EUR"))
                .bold()
        }
        .padding(.vertical, 4)
    }
}
