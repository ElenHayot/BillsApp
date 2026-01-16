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
    
    func loadDashboard(year: Int) async { // ✅ year optionnel
        isLoading = true
        errorMessage = nil
        
        do {
            dashboard = try await APIClient.shared.getDashboard(
                year: year
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

