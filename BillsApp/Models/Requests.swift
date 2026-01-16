//
//  Requests.swift
//  BillsApp
//
//  Created by Elen Hayot on 15/01/2026.
//

import Foundation

struct CreateBillRequest: Encodable {
    let title: String
    let amount: String
    let date: String
    let categoryId: String
    let comment: String?
    
    
}
