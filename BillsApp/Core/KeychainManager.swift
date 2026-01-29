//
//  KeychainManager.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/12/2025.
//
//  Secured refresh token management in IOS keychain
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.billsapp.auth"
    private let refreshTokenKey = "refresh_token"
    
    private init() {}
    
    // MARK: - Save Refresh Token
    /// Save refresh token into keychain
    func saveRefreshToken(_ token: String) {
        // Convert token into data
        guard let data = token.data(using: .utf8) else { return }
        
        // Create the keychain query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete old token if exists
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("❌ Erreur sauvegarde Keychain: \(status)")
        }
    }
    
    // MARK: - Get Refresh Token
    /// Get refresh token from keychain
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
    /// Remove refresh token from keychain (on logout)
    func deleteRefreshToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
