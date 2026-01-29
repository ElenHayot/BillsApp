//
//  SettingsViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 26/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // User settings
    @AppStorage("userLanguage") var userLanguage: String = "fr"
    @AppStorage("userTheme") var userTheme: String = "system"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Charger les préférences depuis UserDefaults
        // Les @AppStorage gèrent cela automatiquement
    }
    
    func updateLanguage(_ language: String) {
        userLanguage = language
        // TODO : Logic to add/modify app language
    }
    
    func updateTheme(_ theme: String) {
        userTheme = theme
        // TODO : Logic to change user design theme
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        // TODO : Logic to manage notifications
    }
}
