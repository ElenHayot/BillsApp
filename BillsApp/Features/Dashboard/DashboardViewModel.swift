//
//  DashboardViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import Foundation
import Combine
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {

    @Published var dashboard: DashboardResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDashboard(token: String) async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "http://127.0.0.1:8000/api/v1/dashboard/?year=2025") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "Server error"
                isLoading = false
                return
            }
            
            // ← POUR DEBUGGER
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 JSON reçu: \(jsonString)")
            }

            let decoded = try JSONDecoder().decode(DashboardResponse.self, from: data)
            dashboard = decoded
        } catch {
            print("❌ Erreur de décodage: \(error)") // ← Plus d'infos sur l'erreur
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

