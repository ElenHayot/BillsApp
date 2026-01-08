//
//  BillsListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 04/01/2026.
//
import Foundation
import Combine
import SwiftUI

@MainActor
final class BillsListViewModel: ObservableObject {

    @Published var bills: [Bill] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadBills(
        token: String,
        categoryId: Int,
        year: Int
    ) async {

        isLoading = true
        errorMessage = nil

        do {
            bills = try await BillsService.shared.fetchBills(
                token: token,
                categoryId: categoryId,
                year: year
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}


