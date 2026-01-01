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

    func loadDashboard(year: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            dashboard = try await APIClient.shared.getDashboard(year: year)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
