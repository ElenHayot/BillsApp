//
//  Category.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
struct Category: Identifiable, Decodable, Hashable {
    let id: Int                // category_id backend
    let name: String
    let color: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case color = "color"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
    }
}
