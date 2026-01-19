//
//  APIClient.swift
//  BillsApp
//
//  Client API avec gestion automatique du refresh token
//

import Foundation

final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://localhost:8000/api/v1")!
    
    // Lock pour éviter les refreshs multiples simultanés
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?

    private init() {}
    
    // MARK: - Generic Request avec Auto-Refresh
    /// Méthode générique qui gère automatiquement le refresh si token expiré
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        var currentRequest = request
        
        // Ajouter le token d'accès
        if let token = AuthStorage.shared.accessToken {
            currentRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: currentRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Si 401 : le token est expiré, on tente un refresh
        if http.statusCode == 401 {
            print("🔄 Token expiré, tentative de refresh...")
            
            // Refresh le token
            let newToken = try await refreshAccessToken()
            
            // Retry la requête avec le nouveau token
            currentRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: currentRequest)
            
            guard let retryHttp = retryResponse as? HTTPURLResponse, retryHttp.statusCode == 200 else {
                throw URLError(.userAuthenticationRequired)
            }
            
            return try decoder.decode(T.self, from: retryData)
        }
        
        guard http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Perform Request(sans réponse décodable)
    /// Pour les requêtes DELETE ou autres qui ne retournent pas de JSON
    private func performRequestWithoutResponse(_request: URLRequest) async throws {
        var currentRequest = _request
        
        if let token = AuthStorage.shared.accessToken {
            currentRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: currentRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 401 {
            print("🔄 Token expiré, tentative de refresh...")
            let newToken = try await refreshAccessToken()
            
            currentRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (_, retryResponse) = try await URLSession.shared.data(for: currentRequest)
            
            guard let retryHttp = retryResponse as? HTTPURLResponse,
                  (200...299).contains(retryHttp.statusCode) else {
                throw URLError(.userAuthenticationRequired)
            }
            return
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.init(rawValue: http.statusCode))
        }
    }
    
    // MARK: - Refresh Access Token
    /// Refresh l'access token en utilisant le refresh token stocké
    private func refreshAccessToken() async throws -> String {
        // Si un refresh est déjà en cours, attendre son résultat
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // Créer une nouvelle tâche de refresh
        let task = Task<String, Error> { () -> String in
            guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
                throw URLError(.userAuthenticationRequired)
            }
            
            var url = baseURL
            url.append(path: "auth/refresh/")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["refresh_token": refreshToken]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Si le refresh échoue, déconnecter l'utilisateur
                await MainActor.run {
                    AuthStorage.shared.accessToken = nil
                    KeychainManager.shared.deleteRefreshToken()
                }
                throw URLError(.userAuthenticationRequired)
            }
            
            let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
            
            // Sauvegarder les nouveaux tokens
            await MainActor.run {
                AuthStorage.shared.accessToken = refreshResponse.accessToken
                KeychainManager.shared.saveRefreshToken(refreshResponse.refreshToken)
            }
            
            return refreshResponse.accessToken
        }
        
        refreshTask = task
        
        defer {
            refreshTask = nil
        }
        
        return try await task.value
    }

    // MARK: - Dashboard
    func getDashboard(year: Int) async throws -> DashboardResponse {
        var url = baseURL
        url.append(path: "dashboard/")
        url.append(queryItems: [
            URLQueryItem(name: "year", value: "\(year)")
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performRequest(request, responseType: DashboardResponse.self)
    }
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> LoginResponse {
        var url = baseURL
        url.append(path: "auth/login/")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "username": email,
            "password": password
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }

        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        // Sauvegarder les tokens
        AuthStorage.shared.accessToken = loginResponse.accessToken
        KeychainManager.shared.saveRefreshToken(loginResponse.refreshToken)
        
        return loginResponse
    }
    
    // MARK: - Logout
    func logout() async throws {
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            return
        }
        
        var url = baseURL
        url.append(path: "auth/logout/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        // On tente de logout sur le serveur, mais on nettoie quoi qu'il arrive
        _ = try? await URLSession.shared.data(for: request)
        
        // Nettoyer les tokens localement
        AuthStorage.shared.accessToken = nil
        KeychainManager.shared.deleteRefreshToken()
    }
    
    // MARK: - Categories
    
    /// Récupère toutes les catégories
    func fetchCategories() async throws -> [Category] {
        var url = baseURL
        url.append(path: "categories/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [Category].self)
    }
    
    /// Crée une nouvelle catégorie
    func createCategory(name: String, color: String) async throws -> Category {
        var url = baseURL
        url.append(path: "categories/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name,
            "color": color
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: Category.self)
    }
    
    /// Met à jour une catégorie
    func updateCategory(categoryName: String, name: String, color: String) async throws -> Category {
        var url = baseURL
        url.append(path: "categories/\(categoryName)/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name,
            "color": color
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: Category.self)
    }
    
    /// Supprime une catégorie
    func deleteCategory(categoryName: String) async throws {
        var url = baseURL
        url.append(path: "categories/\(categoryName)/")
        
         var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
    
    // MARK: - Bills
    
    /// Récupère toutes les factures avec filtres
    func fetchAllBills(
        year: Int,
        categoryId: Int? = nil,
        title: String? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil,
        page: Int = 1,
        pageSize: Int = 20
    ) async throws -> [BillWithCategory] {
        var url = baseURL
        url.append(path: "bills/")
        
        url.append(queryItems: [
                   URLQueryItem(name: "year", value: "\(year)")
               ])
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "year", value: "\(year)")
        ]
        
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: "\(categoryId)"))
        }
        
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: "\(title)"))
        }
        
        if let minAmount = minAmount {
            queryItems.append(URLQueryItem(name: "min_amount", value: "\(minAmount)"))
        }
        
        if let maxAmount = maxAmount {
            queryItems.append(URLQueryItem(name: "max_amount", value: "\(maxAmount)"))
        }
        
        // Ajouter les query items
        url.append(queryItems: queryItems)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bills = try await performRequest(request, responseType: [Bill].self)
        
        
        return bills.map { BillWithCategory(bill: $0, categoryColor: nil) }
//        return bills
    }
    
    /// Récupère toutes les factures associées à une catégorie
    func fetchBillsGroupedByCategory(
        categoryId: Int,
        year: Int
    ) async throws -> [Bill] {
        print("in fetchBillsByCategory, categoryId: \(categoryId), year: \(year)")
        var url = baseURL
        url.append(path: "bills/")
        url.append(queryItems: [
           URLQueryItem(name: "category_id", value: "\(categoryId)"),
           URLQueryItem(name: "year", value: "\(year)")
       ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [Bill].self)
    }
    
    /// Crée une nouvelle facture
    func createBill(
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        providerId: Int?,
        providerName: String,
        comment: String
    ) async throws -> Bill {
        var url = baseURL
        url.append(path: "bills/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: String] = [
            "title": title,
            "amount": NSDecimalNumber(decimal: amount).description,
            "date": ISO8601DateFormatter().string(from: date),
            "category_id": "\(categoryId)",
            "provider_name": providerName,
            "comment": comment
        ]
        if providerId != nil {
            body["provider_id"] = "\(providerId!)"
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request, responseType: Bill.self)
    }
    
    /// Met à jour une facture
    func updateBill (
        billId: Int,
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        providerId: Int?,
        providerName: String,
        comment: String
    ) async throws -> Bill {
        var url = baseURL
        url.append(path: "bills/\(billId)/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: String] = [
            "title": title,
            "amount": NSDecimalNumber(decimal: amount).description,
            "date": ISO8601DateFormatter().string(from: date),
            "category_id": "\(categoryId)",
            "provider_name": providerName,
            "comment": comment
        ]
        
        if providerId != nil {
            body["provider_id"] = "\(providerId!)"
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: Bill.self)
    }
    
    /// Supprime une facture
    func deleteBill(billId: Int) async throws {
        var url =  baseURL
        url.append(path: "bills/\(billId)/")
        
        var request = URLRequest(url : url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
    
    // MARK: - Providers
    
    /// Récupère toutes les  fournisseurs
    func fetchProviders() async throws -> [Provider] {
        var url = baseURL
        url.append(path: "providers/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [Provider].self)
    }
    
    /// Crée un nouveau fournisseur
    func createProvider(name: String) async throws -> Provider {
        var url = baseURL
        url.append(path: "providers/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: Provider.self)
    }
    
    /// Met à jour un fournisseur
    func updateProvider(providerId: Int, name: String) async throws -> Provider {
        var url = baseURL
        url.append(path: "providers/\(providerId)/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: Provider.self)
    }
    
    /// Supprime un fournisseur
    func deleteProvider(providerId: Int) async throws {
        var url = baseURL
        url.append(path: "providers/\(providerId)/")
        
         var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
}


// MARK: - Response Models
//struct LoginResponse: Decodable {
//    let accessToken: String
//    let refreshToken: String
//    
//    enum CodingKeys: String, CodingKey {
//        case accessToken = "access_token"
//        case refreshToken = "refresh_token"
//    }
//}

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
