//
//  AuthModels.swift
//  BillsApp
//
//  Created by Elen Hayot on 01/01/2026.
//

import Foundation

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
