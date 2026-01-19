//
//  ProviderDetailViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 18/01/2026.
//

import Foundation
import Combine

@MainActor
final class ProviderDetailViewModel: ObservableObject {

    @Published var isDeleting = false
    @Published var errorMessage: String?

    func deleteProvider(
        providerId: Int
    ) async -> Bool {

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIClient.shared.deleteProvider(
                providerId: providerId
            )
            return true
        }
        catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
