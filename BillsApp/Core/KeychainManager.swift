//
//  KeychainManager.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
//  Gestion sécurisée du refresh token dans le Keychain iOS
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.billsapp.auth"
    private let refreshTokenKey = "refresh_token"
    
    private init() {}
    
    // MARK: - Save Refresh Token
    /// Sauvegarde le refresh token dans le Keychain de manière sécurisée
    func saveRefreshToken(_ token: String) {
        // Convertir le token en Data
        guard let data = token.data(using: .utf8) else { return }
        
        // Créer le query dictionary pour le Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Supprimer l'ancien token s'il existe
        SecItemDelete(query as CFDictionary)
        
        // Ajouter le nouveau token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("❌ Erreur sauvegarde Keychain: \(status)")
        }
    }
    
    // MARK: - Get Refresh Token
    /// Récupère le refresh token depuis le Keychain
    func getRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    // MARK: - Delete Refresh Token
    /// Supprime le refresh token du Keychain (lors du logout)
    func deleteRefreshToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
