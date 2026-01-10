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
        token: String,
        name: String,
        color: String
    ) async -> Category? {
        
        isCreating = true
        defer { isCreating = false }
        
        do {
            let category = try await CategoryService.shared.createCategory(
                token: token,
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
