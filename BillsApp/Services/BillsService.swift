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
    private let baseURL = "http://localhost:8000/api/v1"

    // MARK: - Fetch all bills (without category filter)

    func fetchAllBills(
        token: String,
        year: Int,
        categoryId: Int? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil
    ) async throws -> [BillWithCategory] {
        
        var components = URLComponents(string: "\(baseURL)/bills/")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "year", value: "\(year)")
        ]
        
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: "\(categoryId)"))
        }
        
        if let minAmount = minAmount {
            queryItems.append(URLQueryItem(name: "min_amount", value: "\(minAmount)"))
        }
        
        if let maxAmount = maxAmount {
            queryItems.append(URLQueryItem(name: "max_amount", value: "\(maxAmount)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Décode un tableau de dictionnaires contenant bill + category info
        // Si ton backend retourne juste des bills, adapte le décodage
        let bills = try decoder.decode([Bill].self, from: data)
        
        // Pour l'instant, on retourne sans couleur de catégorie
        // Tu pourras améliorer ça plus tard en récupérant les catégories
        return bills.map { BillWithCategory(bill: $0, categoryColor: nil) }
    }
    
    // MARK: - Fetch bills with category filter
    
    func fetchBills(
        token: String,
        categoryId: Int,
        year: Int
    ) async throws -> [Bill] {

        var components = URLComponents(string: "\(baseURL)/bills/")!
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
    
    // MARK: - Create bill

    func createBill(
        token: String,
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        comment: String?
    ) async throws -> Bill {
        let urlString = "\(baseURL)/bills/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format la date en ISO8601
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var body: [String: Any] = [
            "title": title,
            "amount": NSDecimalNumber(decimal: amount).doubleValue,
            "date": dateFormatter.string(from: date),
            "category_id": categoryId
        ]
        
        if let comment = comment, !comment.isEmpty {
            body["comment"] = comment
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bill = try decoder.decode(Bill.self, from: data)
        return bill
    }

    // MARK: - Update bill

    func updateBill(
        token: String,
        billId: Int,
        title: String?,
        amount: Decimal?,
        date: Date?,
        categoryId: Int?,
        comment: String?
    ) async throws -> Bill {
        let urlString = "\(baseURL)/bills/\(billId)/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [:]
        
        if let title = title {
            body["title"] = title
        }
        if let amount = amount {
            body["amount"] = NSDecimalNumber(decimal: amount).doubleValue
        }
        if let date = date {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["date"] = dateFormatter.string(from: date)
        }
        if let categoryId = categoryId {
            body["category_id"] = categoryId
        }
        if let comment = comment {
            body["comment"] = comment
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bill = try decoder.decode(Bill.self, from: data)
        return bill
    }
    
    // MARK: - delete bill
    
    func deleteBill (token: String, billId: Int) async throws {
        
        let urlString = "\(baseURL)/bills/\(billId)/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
