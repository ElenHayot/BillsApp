//
//  User.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import Foundation
import SwiftUI
import Combine

struct User: Identifiable, Decodable, Hashable {
    let id = UUID()
    let email: String
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case email = "email"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decode(String.self, forKey: .email)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
