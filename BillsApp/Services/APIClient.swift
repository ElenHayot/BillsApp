//
//  APIClient.swift
//  BillsApp
//
//  API client with automatic refresh token management
//

import Foundation

final class APIClient {
    static let shared = APIClient()

    //private let baseURL = URL(string: "http://localhost:8000/api/v1")!
    private let baseURL = URL(string: "http://172.20.10.3:8000/api/v1")!
    
    // Lock to avoid simultanous multiple refreshes
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?
    private let decoder = JSONDecoder()

    private init() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Request with Auto-Refresh
    /// Geneeric method to manage refresh if access token is expired
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        var currentRequest = request
        
        // Add access token
        if let token = AuthStorage.shared.accessToken {
            currentRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: currentRequest)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        
        // If 401 : access token expired, try to refresh
        if http.statusCode == 401 {
            print("🔄 Token expiré, tentative de refresh...")
            
            // Refresh the access token
            let newToken = try await refreshAccessToken()
            
            // Retry request with new access token
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
    
    // MARK: - Perform Request(without decodable response)
    /// For DELETE requests not returning JSON
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
    /// Refresh access token
    func refreshAccessToken() async throws -> String {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // New refresh task
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
                // If refresh fails, logout user
                await MainActor.run {
                    AuthStorage.shared.accessToken = nil
                    KeychainManager.shared.deleteRefreshToken()
                }
                throw URLError(.userAuthenticationRequired)
            }
            
            let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
            
            // Save new token
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
        
        let loginResponse = try decoder.decode(LoginResponse.self, from: data)
        
        // Save tokens
        AuthStorage.shared.accessToken = loginResponse.accessToken
        AuthStorage.shared.currentUser = loginResponse.currentUser
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
        
        // Try to logout and clear
        _ = try? await URLSession.shared.data(for: request)
        
        // Clear all local tokens
        AuthStorage.shared.accessToken = nil
        KeychainManager.shared.deleteRefreshToken()
    }
    
    // MARK: - Users
    
    /// Fetch all users
    func fetchUsers() async throws -> [User] {
        var url = baseURL
        url.append(path: "users/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [User].self)
    }
    
    /// Create a new user account
    func createUser(email: String, password: String) async throws -> User {
        var url = baseURL
        url.append(path: "users/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request, responseType: User.self)
    }
    
    /// Update an existing user
    func updateUser(email: String, password: String) async throws -> User {
        var url = baseURL
        url.append(path: "users/\(email)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let user = try await performRequest(request, responseType: User.self)
        AuthStorage.shared.currentUser = user
        
        return user
    }
    
    // MARK: - Categories
    
    /// Fetch all categories
    func fetchCategories() async throws -> [Category] {
        var url = baseURL
        url.append(path: "categories/")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [Category].self)
    }
    
    /// Create a new category
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
    
    /// Update an existing category
    func updateCategory(categoryId: Int, name: String, color: String) async throws -> Category {
        var url = baseURL
        url.append(path: "categories/\(categoryId)/")
        
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
    
    /// Delete a category
    func deleteCategory(categoryId: Int) async throws {
        var url = baseURL
        url.append(path: "categories/\(categoryId)/")
        
         var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
    
    // MARK: - Bills
    
    /// Fetch all bills with applied filters
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
        
        // Add query items
        url.append(queryItems: queryItems)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bills = try await performRequest(request, responseType: [Bill].self)
        
        // Return bills mapped with category
        return bills.map { BillWithCategory(bill: $0, categoryColor: nil) }
    }
    
    /// Fetch all bills grouped by category
    func fetchBillsGroupedByCategory(
        categoryId: Int,
        year: Int
    ) async throws -> [Bill] {
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
    
    /// Create a bill
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
    
    /// Update a bill
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
    
    /// Delete a bill
    func deleteBill(billId: Int) async throws {
        var url =  baseURL
        url.append(path: "bills/\(billId)/")
        
        var request = URLRequest(url : url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
    
    // MARK: - Providers
    
    /// Fetch all providers
    func fetchProviders(
        name: String? = nil,
        page: Int = 1,
        pageSize: Int = 20
    ) async throws -> [Provider] {
        var url = baseURL
        url.append(path: "providers/")
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        
        if let name = name {
            queryItems.append(URLQueryItem(name: "name", value: "\(name)"))
        }
        
        // Add query items
        url.append(queryItems: queryItems)
                            
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request, responseType: [Provider].self)
    }
    
    /// Create a provider
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
    
    /// Update an existing provider
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
    
    /// Delete a provider
    func deleteProvider(providerId: Int) async throws {
        var url = baseURL
        url.append(path: "providers/\(providerId)/")
        
         var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        try await performRequestWithoutResponse(_request: request)
    }
}


// MARK: - Response Models

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
