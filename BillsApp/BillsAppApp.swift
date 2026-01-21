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
    @StateObject private var createUserVM = UserFormViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(createUserVM)
        }
    }
}
