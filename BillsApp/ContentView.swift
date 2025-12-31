//
//  ContentView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if authVM.isAuthenticated {
            DashboardView()
        } else {
            LoginView()
        }
    }
}
