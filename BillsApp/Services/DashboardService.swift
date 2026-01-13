//
//  DashboardService.swift
//  BillsApp
//
//  Created by Elen Hayot on 11/01/2026.
//

import Foundation

final class DashboardService {
    
    static let shared = DashboardService()
    
    private init() {}
    
    private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!
    
    func fetchDashboard(token: String, year: Int? = nil) async throws -> DashboardResponse {
        var urlString = "\(baseURL)/dashboard/"
        
        // ✅ Ajoute le paramètre year si fourni
        if let year = year {
            urlString += "?year=\(year)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let decoder = JSONDecoder()
        let dashboard = try decoder.decode(DashboardResponse.self, from: data)
        return dashboard
    }
}
