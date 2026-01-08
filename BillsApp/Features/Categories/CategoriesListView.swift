//
//  CategoriesListView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoriesListView: View {
    
    let token: String
    
    @StateObject private var viewModel = CategoriesViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Categories")
                .font(.largeTitle)
                .padding(.bottom, 8)
            
            if viewModel.isLoading {
                ProgressView("Loading categories…")
            }
            else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            else if viewModel.categories.isEmpty {
                Text("No categories")
                    .foregroundColor(.secondary)
            }
            else {
                List(viewModel.categories) { category in
                    CategoryRowView(category: category)
                }
            }
        }
        .padding()
        .task {
            await viewModel.loadCategories(token: token)
        }
    }
}
