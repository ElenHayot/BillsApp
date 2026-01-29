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
    
    // Préférences utilisateur
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
        // Ici tu pourrais ajouter la logique pour changer la langue de l'appli
    }
    
    func updateTheme(_ theme: String) {
        userTheme = theme
        // Ici tu pourrais ajouter la logique pour changer le thème
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        // Ici tu pourrais ajouter la logique pour gérer les notifications
    }
}
