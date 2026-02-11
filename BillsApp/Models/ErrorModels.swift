//
//  ErrorModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 04/02/2026.
//

import Foundation

struct APIError: Decodable {
    let detail: String
}

// Main backend error structure (sending {"detail": {...}})
struct BackendErrorWrapper: Decodable {
    let detail: BackendErrorDetail
}

// Error structure in "detail"
struct BackendErrorDetail: Decodable {
    let errorCode: String
    let params: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case params
    }
}

// Helper to decode Any in JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: value))
    }
}

// Network errors enum with user-friendly messages
enum NetworkError: LocalizedError {
    case badServerResponse
    case unauthorized(String?)
    case backendError(code: String, params: [String: AnyCodable]?)
    case decodingError
    case timeout
    case unknown(Int, String?)
    
    var errorDescription: String? {
        switch self {
        case .badServerResponse:
            return "Réponse du serveur invalide"
            
        case .unauthorized(let message):
            return message ?? "Session expirée, veuillez vous reconnecter"
            
        case .backendError(let code, let params):
            return userFriendlyMessage(for: code, params: params)
            
        case .decodingError:
            return "Erreur lors du traitement des données"
            
        case .timeout:
            return "Le serveur ne répond pas. Vérifiez votre connexion."
            
        case .unknown(let statusCode, let message):
            return message ?? "Erreur inconnue (code: \(statusCode))"
        }
    }
    
    // Convert backend error_code into user-friendly messages
    private func userFriendlyMessage(for code: String, params: [String: AnyCodable]?) -> String {
        switch code {
        // Auth errors
        case "UNAUTHORIZED":
            return "Vous devez être connecté pour effectuer cette action"
            
        case "FORBIDDEN":
            let resource = params?["resource"]?.value as? String ?? "cette ressource"
            return "Vous n'avez pas les permissions pour modifier \(resource)"
                
        case "TOKEN_EXPIRED":
            return "Session expirée, veuillez vous reconnecter"
            
        case "ACCOUNT_LOCKED":
            return "Votre compte a été temporairement bloqué. Veuillez essayer plus tard."
            
        // User errors
        case "EMAIL_ALREADY_EXISTS":
            if let email = params?["email"]?.value as? String {
                return "L'adresse email \(email) est déjà utilisée"
            }
            return "Cette adresse email est déjà utilisée"
            
        case "USER_NOT_FOUND":
            return "Utilisateur introuvable"
            
        case "INVALID_EMAIL":
            return "Adresse email invalide"
            
        case "INVALID_CREDENTIALS":
            return "Email ou mot de passe incorrect"
            
        // Generic errors
        case "ALREADY_EXISTS":
            return "Cet élément existe déjà"
            
        case "RESOURCE_NOT_FOUND":
            return "Ressource introuvable"
        
        case "DELETE_CONFLICT":
            return "Vous ne pouvez pas supprimer ce contenu car il est utilisé quelque part"
            
        case "VALIDATION_ERROR":
            if let field = params?["field"]?.value as? String {
                return "Erreur de validation sur le champ : \(field)"
            }
            return "Erreur de validation"
            
        case "INTERNAL_ERROR":
            return "Une erreur est survenue. Veuillez réessayer."
            
        case "DATABASE_ERROR":
            return "Une erreur est survenue lors de l'enregistrement. Veuillez réessayer."
            
        default:
            return "Une erreur est survenue : \(code)"
        }
    }
}
