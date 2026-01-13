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
final class DashboardViewModel: ObservableObject {
    
    @Published var dashboard: DashboardResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadDashboard(token: String, year: Int? = nil) async { // ✅ year optionnel
        isLoading = true
        errorMessage = nil
        
        do {
            dashboard = try await DashboardService.shared.fetchDashboard(
                token: token,
                year: year // ✅ Passe l'année au service
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

