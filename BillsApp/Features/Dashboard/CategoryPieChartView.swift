//
//  CategoryPieChartView.swift
//  BillsApp
//
//  Created by Elen Hayot on 02/01/2026.
//

import Foundation
import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let categories: [DashboardCategoryStats]
    let onCategorySelected: (DashboardCategoryStats) -> Void
    
    @State private var selectedCategoryName: String?
    
    var body: some View {
        Chart(categories) { category in
            SectorMark(
                angle: .value("Total", category.totalAmount),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(Color(hex: category.categoryColor))
            .opacity(selectedCategoryName == category.categoryName ? 1 : 0.7)
            .annotation(position: .overlay) {
                Text(category.categoryName)
                    .font(.caption)
                    .bold(selectedCategoryName == category.categoryName)
            }
        }
        .chartAngleSelection(value: $selectedCategoryName)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        // Trouve la catégorie à cette position
                        let angle = proxy.angle(at: location)
                        
                        // Sélectionne via le nom pour déclencher chartAngleSelection
                        if let foundCategory = findCategory(at: angle) {
                            selectedCategoryName = foundCategory.categoryName
                            onCategorySelected(foundCategory)
                        }
                    }
            }
        }
        .frame(height: 260)
    }
    
    private func findCategory(at angle: Angle) -> DashboardCategoryStats? {
        let total = categories.reduce(Decimal(0)) { $0 + $1.totalAmount }
        guard total > 0 else { return nil }
        
        var currentAngle: Double = 0
        let targetAngle = angle.degrees.truncatingRemainder(dividingBy: 360)
        
        for category in categories {
            let categoryAngle = (Double(truncating: category.totalAmount as NSNumber) / Double(truncating: total as NSNumber)) * 360
            
            if targetAngle >= currentAngle && targetAngle < currentAngle + categoryAngle {
                return category
            }
            currentAngle += categoryAngle
        }
        
        return nil
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
