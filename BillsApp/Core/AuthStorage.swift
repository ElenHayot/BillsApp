//
//  AuthStorage.swift
//  BillsApp
//
//  Created by Elen Hayot on 31/12/2025.
//

final class AuthStorage {
    static let shared = AuthStorage()

    var accessToken: String?

    private init() {}
}
