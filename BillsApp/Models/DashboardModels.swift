//
//  DashboardModels.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//

import Foundation

struct DashboardResponse: Decodable {
    let year: Int
    let currency: String
    let globalStats: DashboardGlobalStats
    let byCategory: [DashboardCategoryStats]

    private enum CodingKeys: String, CodingKey {
        case year
        case currency
        case globalStats = "global_stats"
        case byCategory = "by_category"
    }
}

struct DashboardGlobalStats: Decodable {
    let nbBills: Int
    let totalAmount: Decimal

    private enum CodingKeys: String, CodingKey {
        case nbBills = "nb_bills"
        case totalAmount = "total_amount"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nbBills = try container.decode(Int.self, forKey: .nbBills)
        
        // Gère à la fois String et Number
        if let stringValue = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = Decimal(string: stringValue) ?? 0
        } else if let doubleValue = try? container.decode(Double.self, forKey: .totalAmount) {
            totalAmount = Decimal(doubleValue)
        } else {
            totalAmount = 0
        }
    }
}

struct DashboardCategoryStats: Decodable, Identifiable {
    let id = UUID()
    let categoryName: String
    let categoryColor: String
    let nbBills: Int
    let totalAmount: Decimal

    private enum CodingKeys: String, CodingKey {
        case categoryName = "category_name"
        case categoryColor = "category_color"
        case nbBills = "nb_bills"
        case totalAmount = "total_amount"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        categoryColor = try container.decode(String.self, forKey: .categoryColor)
        nbBills = try container.decode(Int.self, forKey: .nbBills)
        
        // Gère à la fois String et Number
        if let stringValue = try? container.decode(String.self, forKey: .totalAmount) {
            totalAmount = Decimal(string: stringValue) ?? 0
        } else if let doubleValue = try? container.decode(Double.self, forKey: .totalAmount) {
            totalAmount = Decimal(doubleValue)
        } else {
            totalAmount = 0
        }
    }
}

extension DashboardGlobalStats {

    var totalAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "fr_FR")

        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "0 €"
    }
}

extension DashboardCategoryStats {

    var totalAmountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "fr_FR")

        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "0 €"
    }
}
