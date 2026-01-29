//
//  CategoryBarChartView.swift
//  BillsApp
//
//  Created by Elen Hayot on 02/01/2026.
//

import Foundation
import SwiftUI
import Charts

struct CategoryBarChartView: View {
    let categories: [DashboardCategoryStats]
    let onCategorySelected: (DashboardCategoryStats) -> Void
    
    @State private var hoveredCategoryName: String?
    
    var body: some View {
        Chart(categories) { category in
            BarMark(
                x: .value("Catégorie", category.categoryName),
                y: .value("Total", category.totalAmount)
            )
            .foregroundStyle(Color(hex: category.categoryColor))
            .opacity(hoveredCategoryName == category.categoryName ? 1 : 0.7)
        }
        .frame(height: 300)
        .chartXSelection(value: $hoveredCategoryName)  // Pour l'effet visuel au survol
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        // Find the category at this x position
                        if let categoryName: String = proxy.value(atX: location.x) {                            
                            if let category = categories.first(where: { $0.categoryName == categoryName }) {
                                onCategorySelected(category)
                            }
                        }
                    }
            }
        }
    }
}
