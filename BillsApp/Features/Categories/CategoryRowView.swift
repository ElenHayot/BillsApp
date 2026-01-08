//
//  CategoryRowView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct CategoryRowView: View {
    
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            // Pastille de couleur
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 24, height: 24)
            
            Text(category.name)
                .font(.headline)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
