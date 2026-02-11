//
//  BillFormViewModel.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import Foundation
import Combine

@MainActor
final class BillFormViewModel: ObservableObject {
    
    @Published var categories: [Category] = []
    @Published var providers: [Provider] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await APIClient.shared.fetchCategories()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }
        
        isLoading = false
    }
    
    func loadProviders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            providers = try await APIClient.shared.fetchProviders()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
        }
        
        isLoading = false
    }
    
    func fetchProvider(name: String) async -> Provider? {
        isLoading = true
        errorMessage = nil
        
        do {
            let provider = try await APIClient.shared.fetchProviders(name: name).first
            isLoading = false
            return provider
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isLoading = false
            return nil
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isLoading = false
            return nil
            
        }
    }
    
    func createBill(
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        providerId: Int?,
        providerName: String,
        comment: String
    ) async throws -> Bill? {
        
        isSaving = true
        defer { isSaving = false }
        do {
            let bill = try await APIClient.shared.createBill(
                title: title,
                amount: amount,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName,
                comment: comment
            )
            
            successMessage = "Facture créée avec succès !"
            return bill
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isSaving = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isSaving = false
            throw error
        }
    }
    
    func updateBill(
        billId: Int,
        title: String,
        amount: Decimal,
        date: Date,
        categoryId: Int,
        providerId: Int?,
        providerName: String,
        comment: String
    ) async throws -> Bill? {
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let bill = try await APIClient.shared.updateBill(
                billId: billId,
                title: title,
                amount: amount,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName,
                comment: comment
            )
            
            successMessage = "Facture mise à jour avec succès !"
            return bill
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            isSaving = false
            throw error
            
        } catch {
            errorMessage = "Une erreur inattendue est survenue"
            isSaving = false
            throw error
        }
    }
}
