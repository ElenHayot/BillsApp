//
//  APIClient.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//

import Foundation

final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!

    private init() {}

    func getDashboard(year: Int) async throws -> DashboardResponse {
        var url = baseURL
        url.append(path: "dashboard")
        url.append(queryItems: [
            URLQueryItem(name: "year", value: "\(year)")
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Authorization
        if let token = AuthStorage.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }

        return try JSONDecoder().decode(DashboardResponse.self, from: data)
    }
}

extension APIClient {
    func login(email: String, password: String) async throws -> LoginResponse {
            var url = baseURL
            url.append(path: "auth/login/")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let body = [
                "username": email,
                "password": password
            ]

            request.httpBody = body
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
                .data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.userAuthenticationRequired)
            }

            return try JSONDecoder().decode(LoginResponse.self, from: data)
        }
}
