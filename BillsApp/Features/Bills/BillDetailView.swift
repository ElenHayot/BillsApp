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
    
    // Récupère le viewModel de la liste
    @EnvironmentObject private var listViewModel: BillsListViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = BillDetailViewModel()
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
            
            if bill.providerId != nil {
                Divider()
                Text("Fournisseur :")
                    .foregroundColor(.secondary)
                Text("\(String(bill.providerId!)) - \(bill.providerName ?? "Inconnu")")
            } else {
                Divider()
                Text("Fournisseur :")
                    .foregroundColor(.secondary)
                Text("\(bill.providerName ?? "Fournisseur inconnu")")
            }

            if let comment = bill.comment, !comment.isEmpty {
                Divider()
                Text("Commentaire")
                    .foregroundColor(.secondary)
                Text(comment)
            }

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView()
                } else {
                    Text("Supprimer la facture")
                }
            }
        }
        .padding()
        .navigationTitle("Bill")
        .alert("Supprimer cette facture ?", isPresented: $showDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                Task {
                    let success = await viewModel.deleteBill(
                        billId: bill.id
                    )
                    if success {
                        print("✅ Suppression réussie, suppression locale pour bill \(bill.id)")
                        // ✅ Supprime directement dans le viewModel
                        listViewModel.bills.removeAll { $0.id == bill.id }
                        dismiss()
                    } else {
                        print("❌ Échec de la suppression")
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - helpers
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
