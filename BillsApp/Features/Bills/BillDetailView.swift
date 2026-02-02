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
    
    @EnvironmentObject private var listViewModel: BillsListViewModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = BillDetailViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    detailsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    actionsCard
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.systemGroupedBackground)
        }
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

    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Text(bill.amountFormatted)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
            
            Text(bill.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Details Card
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            infoRow(label: "Date", value: bill.dateFormatted)
            
            Divider()
                .padding(.leading, 16)
            
            infoRow(
                label: "Fournisseur", 
                value: bill.providerId != nil 
                    ? "\(bill.providerId!) - \(bill.providerName ?? "Inconnu")"
                    : bill.providerName ?? "Fournisseur inconnu"
            )
            
            if let comment = bill.comment, !comment.isEmpty {
                Divider()
                    .padding(.leading, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commentaire")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    Text(comment)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        VStack(spacing: 0) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    if viewModel.isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .font(.title3)
                    }
                    
                    Text("Supprimer la facture")
                        .font(.headline)
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDeleting)
        }
        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
