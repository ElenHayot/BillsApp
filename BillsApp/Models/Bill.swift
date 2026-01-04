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
}
