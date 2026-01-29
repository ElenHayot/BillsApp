//
//  UserEditViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 26/01/2026.
//

import Foundation
import Combine

@MainActor
class UserEditViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shouldDismiss = false
    
    func updateUser(email: String, currentPassword: String?, newPassword: String?) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Simuler une mise à jour (à remplacer par ta vraie logique)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            
            // Ici tu mettrais ta vraie logique de mise à jour
            // Par exemple :
            // try await authService.updateUser(email: email, currentPassword: currentPassword, newPassword: newPassword)
            
            successMessage = "Profil mis à jour avec succès"
            shouldDismiss = true
            
        } catch {
            errorMessage = "Erreur lors de la mise à jour : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
