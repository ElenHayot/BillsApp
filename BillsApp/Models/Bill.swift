//
//  Bill.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import Foundation

struct Bill: Identifiable, Decodable {
    let id: Int
    let title: String
    let amount: Decimal
    let date: Date
    let categoryId: Int
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case amount = "amount"
        case date = "date"
        case categoryId = "category_id"
        case comment = "comment"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Gère à la fois String et Number
        if let stringValue = try? container.decode(String.self, forKey: .amount) {
            amount = Decimal(string: stringValue) ?? 0
        } else if let doubleValue = try? container.decode(Double.self, forKey: .amount) {
            amount = Decimal(doubleValue)
        } else {
            amount = 0
        }
    }
}
