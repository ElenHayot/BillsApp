//
//  CategoriesListViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadCategories(token: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await CategoryService.shared.fetchCategories(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
