//
//  DashboardView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        VStack {
            if let dashboard = vm.dashboard {
                Text("Total: \(dashboard.globalStats.totalAmount) \(dashboard.currency)")
            } else if vm.isLoading {
                ProgressView()
            } else {
                Text("No data")
            }
        }
        .task {
            await vm.loadDashboard(year: Calendar.current.component(.year, from: Date()))
        }
    }
}
