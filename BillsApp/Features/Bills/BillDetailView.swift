//
//  BillDetailView.swift
//  BillsApp
//
//  Created by Elen Hayot on 05/01/2026.
//

import Foundation
import SwiftUI

struct BillDetailView: View {

    let bill: Bill
    let token: String

    @StateObject private var viewModel = BillDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(bill.amountFormatted)
                .font(.system(size: 34, weight: .bold))

            Text(bill.title)
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            infoRow(label: "Date", value: bill.dateFormatted)
//            infoRow(label: "Category", value: bill.categoryName)

            if let comment = bill.comment, !comment.isEmpty {
                Divider()
                Text("Comment")
                    .foregroundColor(.secondary)
                Text(comment)
            }

            Spacer()

            // 🗑 Delete
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView()
                } else {
                    Text("Delete bill")
                }
            }
        }
        .padding()
        .navigationTitle("Bill")
//        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this bill?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    let success = await viewModel.deleteBill(
                        token: token,
                        billId: bill.id
                    )
                    if success {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
