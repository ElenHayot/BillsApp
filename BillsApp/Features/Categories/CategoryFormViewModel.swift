//
//  CategoryFormViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class CategoryFormViewModel: ObservableObject {
    
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    func createCategory(
        name: String,
        color: String
    ) async -> Category? {
        
        isCreating = true
        defer { isCreating = false }
        
        do {
            let category = try await APIClient.shared.createCategory(
                name: name,
                color: color
            )
            return category
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
