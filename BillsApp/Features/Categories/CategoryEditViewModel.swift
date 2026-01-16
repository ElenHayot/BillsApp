//
//  CategoryEditViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 10/01/2026.
//

import Foundation
import Combine

@MainActor
final class CategoryEditViewModel: ObservableObject {
    
    @Published var isUpdating = false
    @Published var errorMessage: String?
    
    func updateCategory(
        categoryName: String,
        name: String,
        color: String
    ) async -> Category? {
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            let category = try await APIClient.shared.updateCategory(
                categoryName: categoryName,
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
