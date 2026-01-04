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
}
