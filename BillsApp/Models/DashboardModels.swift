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
    let globalStats: GlobalStats
    let byCategory: [CategoryStats]

    private enum CodingKeys: String, CodingKey {
        case year
        case currency
        case globalStats = "global_stats"
        case byCategory = "by_category"
    }
}

struct GlobalStats: Decodable {
    let nbBills: Int
    let totalAmount: Decimal

    private enum CodingKeys: String, CodingKey {
        case nbBills = "nb_bills"
        case totalAmount = "total_amount"
    }
}

struct CategoryStats: Decodable, Identifiable {
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
}
