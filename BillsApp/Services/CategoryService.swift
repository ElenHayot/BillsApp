//
//  CategoryService.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation

final class CategoryService {
    
    static let shared = CategoryService()
    
    private init() {}
    
    private let baseURL = "http://localhost:8000/api/v1"
    
    // MARK: - Fetch all categories
    
    func fetchCategories(token: String) async throws -> [Category] {
        let urlString = "\(baseURL)/categories/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let categories = try JSONDecoder().decode([Category].self, from: data)
        return categories
    }
    
    // MARK: - Create category
    
    func createCategory(
        token: String,
        name: String,
        color: String
    ) async throws -> Category {
        let urlString = "\(baseURL)/categories/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "color": color
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let category = try JSONDecoder().decode(Category.self, from: data)
        return category
    }
    
    // MARK: - Update category
    
    func updateCategory(
        token: String,
        categoryId: Int,
        categoryName: String,
        name: String,
        color: String
    ) async throws -> Category {
        let urlString = "\(baseURL)/categories/\(categoryName)/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "color": color
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let category = try JSONDecoder().decode(Category.self, from: data)
        return category
    }
    
    // MARK: - Delete category
    
    func deleteCategory(
        token: String,
        categoryId: Int,
        categoryName: String
    ) async throws {
        let urlString = "\(baseURL)/categories/\(categoryName)/"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
    }
}
