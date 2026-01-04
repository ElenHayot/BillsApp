//
//  BillService.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import Foundation

final class BillsService {

    static let shared = BillsService()
    private init() {}

    func fetchBills(
        token: String,
        categoryId: Int,
        year: Int
    ) async throws -> [Bill] {

        var components = URLComponents(string: "http://127.0.0.1:8000/api/v1/bills/")!
        components.queryItems = [
            .init(name: "category_id", value: "\(categoryId)"),
            .init(name: "year", value: "\(year)")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([Bill].self, from: data)
    }
}
