//
//  BillsAppApp.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//

import SwiftUI

@main
struct BillsAppApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
    }
}
