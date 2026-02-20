//
//  ScanProcessingView.swift
//  BillsApp
//
//  Created by Elen Hayot on 22/01/2026.
//

import SwiftUI
import Vision

#if os(iOS)
import UIKit

struct ScanProcessingView: View {
    let image: UIImage
    let onSaved: () -> Void
    let onSuccess: (String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BillFormViewModel()
    
    @State private var isProcessing = true
    @State private var extractedText = ""
    @State private var ocrError: String?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategoryId: Int?
    @State private var selectedProviderId: Int?
    @State private var providerName: String = ""
    @State private var comment: String = ""
    
    @State private var showProviderAlert = false
    @State private var providerToCreate: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, amount, providerName, comment
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    imageSection
                    
                    if isProcessing {
                        processingSection
                    } else if let error = ocrError {
                        errorSection(error)
                    } else {
                        formSection
                        
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Scanner une facture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        focusedField = nil
                    }
                }
            }
        }
        .task {
            await viewModel.loadCategories()
            await viewModel.loadProviders()
            await performOCR()
        }
        .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Créer un nouveau fournisseur ?", isPresented: $showProviderAlert) {
            Button("Non") {
                // Créer la facture sans le provider
                Task {
                    await saveBillForceWithoutProvider()
                }
            }
            Button("Oui") {
                Task {
                    await createNewProvider()
                }
            }
        } message: {
            Text("Le fournisseur \"\(providerToCreate)\" n'existe pas. Souhaitez-vous le créer ?")
        }
    }
    
    // MARK: - Sections
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image capturée")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
    
    private var processingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Analyse de la facture...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Erreur d'analyse")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Réessayer") {
                Task {
                    await performOCR()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Extract text (collapsible for debug)
            if !extractedText.isEmpty {
                DisclosureGroup("Texte extrait (debug)") {
                    Text(extractedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Divider()
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre")
                    .font(.headline)
                
                TextField("Titre de la facture", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .title)
            }
            
            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Montant")
                    .font(.headline)
                
                TextField("0.00", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
            }
            
            // Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.headline)
                
                HStack {
                    Text(formattedDate)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            
            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Catégorie")
                    .font(.headline)
                
                if viewModel.categories.isEmpty {
                    Text("Pas de catégorie disponible")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Sélectionner catégorie", selection: $selectedCategoryId) {
                        Text("Sélectionne une catégorie").tag(nil as Int?)
                        ForEach(viewModel.categories) { category in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: category.color))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(category.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Provider
            VStack(alignment: .leading, spacing: 8) {
                Text("Fournisseur (optionnel)")
                    .font(.headline)
                
                if viewModel.providers.isEmpty {
                    Text("Pas de fournisseur disponible")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Sélectionner fournisseur", selection: $selectedProviderId) {
                        Text("Sélectionne un fournisseur").tag(nil as Int?)
                        ForEach(viewModel.providers) { provider in
                            Text(provider.name).tag(provider.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Provider name
            VStack(alignment: .leading, spacing: 8) {
                Text("Nom du fournisseur")
                    .font(.headline)
                
                TextEditor(text: $providerName)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .providerName)
            }
            
            // Comment
            VStack(alignment: .leading, spacing: 8) {
                Text("Commentaire (optionnel)")
                    .font(.headline)
                
                TextEditor(text: $comment)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .comment)
            }
        }
    }
    
    private var actionButtons: some View {
        Button {
            Task {
                await saveBill()
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Créer la facture")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isFormValid || viewModel.isSaving)
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !amount.isEmpty &&
        Decimal(string: amount) != nil &&
        selectedCategoryId != nil
    }
    
    // Format field
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - OCR
    
    private func performOCR() async {
        isProcessing = true
        ocrError = nil
        
        guard let cgImage = image.cgImage else {
            ocrError = "Impossible de traiter l'image"
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                ocrError = "Erreur OCR: \(error.localizedDescription)"
                isProcessing = false
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                ocrError = "Aucun texte détecté"
                isProcessing = false
                return
            }
            
            // Extract full text
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            extractedText = recognizedStrings.joined(separator: "\n")
            
            // Parse text
            parseInvoiceData(from: extractedText)
            
            isProcessing = false
        }
        // OCR configuration
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["fr-FR", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            ocrError = "Erreur lors de l'analyse: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    private func parseInvoiceData(from text: String) {
        let lines = text.components(separatedBy: .newlines)
        
        // AMOUNT - Use extractAmount function to apply intelligent strategy
        if let detectedAmount = extractAmount(from: text) {
            amount = String(format: "%.2f", detectedAmount)
        }
        
        // DATE - Choose patterns like "12/01/2026" or "12 janvier 2026"
        for line in lines {
            if let detectedDate = extractDate(from: line) {
                date = detectedDate
                break
            }
        }
        
        // PROVIDER - Take first non-empty lines, avoiding "facture"
        var providerLines: [String] = []
        let excludedWords = ["facture", "invoice", "bill", "devis", "quote"]
        
        for line in lines.prefix(5) { // Take max the 5th first lines
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ignore empty and shortest lines
            if cleanLine.count < 2 { continue }
            
            // Ignore word "facture" and similar
            let lowercased = cleanLine.lowercased()
            if excludedWords.contains(where: { lowercased == $0 || lowercased.hasPrefix($0 + " ") }) {
                continue
            }
            
            // Ignore if look like date or amount
            if cleanLine.contains("/") || cleanLine.contains("€") || cleanLine.contains("EUR") {
                continue
            }
            
            providerLines.append(cleanLine)
            
            // Take max 2 lines for provider name
            if providerLines.count == 2 { break }
        }
        
        if !providerLines.isEmpty {
            providerName = providerLines.joined(separator: " ")
        }
        
        // TITLE - Generate default title
        if !providerName.isEmpty {
            title = "Facture \(providerName)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            title = "Facture du \(formatter.string(from: date))"
        }
        
        // COMMENT - Empty by default (user can modifiate)
        comment = ""
    }
    
    private func extractAmount(from text: String) -> Double? {
        let lines = text.components(separatedBy: .newlines)
        print("🔍 [EXTRACT] Début extraction montant avec \(lines.count) lignes")
        
        // 1st STRATEGY: Search "Solde à payer" or "Reste à payer"
        for i in 0..<lines.count {
            let lineUpper = lines[i].uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if (lineUpper.contains("SOLDE") && lineUpper.contains("PAYER")) ||
               (lineUpper.contains("RESTE") && lineUpper.contains("PAYER")) {
                print("✅ [STRAT1] Ligne 'Solde/Reste à payer' trouvée: \(lines[i])")
                
                var amountsAroundSolde: [Double] = []
                
                // Search in this line
                if let amount = extractBestNumberFromLine(lines[i]) {
                    amountsAroundSolde.append(amount)
                }
                // Then search in the 3 following
                for j in 1...3 {
                    if i + j < lines.count {
                        print("🔎 [STRAT1] Vérification ligne \(i+j): \(lines[i+j])")
                        if let amount = extractBestNumberFromLine(lines[i + j]) {
                            amountsAroundSolde.append(amount)
                        }
                    }
                }
                
                if let maxAmount = amountsAroundSolde.max() {
                    print("💰 [STRAT1] Plus grand montant autour de 'Solde/Reste à payer': \(maxAmount)")
                    return maxAmount
                } else {
                    print("❌ [STRAT1] Aucun montant trouvé autour de 'Solde/Reste à payer'")
                }
            }
        }
        
        // 2ns STRATEGY: Search "Montant :" or "Montant à payer"
        for i in 0..<lines.count {
            let lineUpper = lines[i].uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if lineUpper.contains("MONTANT") && (lineUpper.contains(":") || lineUpper.contains("PAYER")) {
                print("✅ [STRAT2] Ligne 'Montant' trouvée: \(lines[i])")
                
                var amountsAroundMontant: [Double] = []
                
                // Search in this line
                if let amount = extractBestNumberFromLine(lines[i]) {
                    amountsAroundMontant.append(amount)
                }
                
                // Then search in the 2 following
                for j in 1...2 {
                    if i + j < lines.count {
                        print("🔎 [STRAT2] Vérification ligne \(i+j): \(lines[i+j])")
                        if let amount = extractBestNumberFromLine(lines[i + j]) {
                            amountsAroundMontant.append(amount)
                        }
                    }
                }
                
                if let maxAmount = amountsAroundMontant.max() {
                    print("💰 [STRAT2] Plus grand montant autour de 'Montant': \(maxAmount)")
                    return maxAmount
                } else {
                    print("❌ [STRAT2] Aucun montant trouvé autour de 'Montant'")
                }
            }
        }
        
        // 3rd STRATEGY: Search "Total TTC" or "TOTAL TTC"
        for i in 0..<lines.count {
            let lineUpper = lines[i].uppercased()
            
            if lineUpper.contains("TOTAL") && lineUpper.contains("TTC") {
                print("✅ [STRAT3] Ligne 'Total TTC' trouvée: \(lines[i])")
                
                var amountsAroundTTC: [Double] = []
                
                if let amount = extractBestNumberFromLine(lines[i]) {
                    amountsAroundTTC.append(amount)
                }
                for j in 1...2 {
                    if i + j < lines.count {
                        print("🔎 [STRAT3] Vérification ligne \(i+j): \(lines[i+j])")
                        if let amount = extractBestNumberFromLine(lines[i + j]) {
                            amountsAroundTTC.append(amount)
                        }
                    }
                }
                
                if let maxAmount = amountsAroundTTC.max() {
                    print("💰 [STRAT3] Plus grand montant autour de 'Total TTC': \(maxAmount)")
                    return maxAmount
                } else {
                    print("❌ [STRAT3] Aucun montant trouvé autour de 'Total TTC'")
                }
            }
        }
        
        // 4th STRATEGY: Search "Total" ALONE but EXCLUDE lines with "KG", "TN", weight, quantities
        for i in 0..<lines.count {
            let lineTrimmed = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if lineTrimmed.uppercased() == "TOTAL" {
                print("✅ [STRAT4] Ligne exacte 'Total' trouvée à ligne \(i)")
                
                var amountsAroundTotal: [Double] = []
                
                // Search in 5 following lines excluding lines with weight/quantities
                for j in 1...5 {
                    if i + j < lines.count {
                        let checkLine = lines[i + j].uppercased()
                        if !checkLine.contains("KG") && !checkLine.contains("TN") &&
                           !checkLine.contains("QUANTITE") && !checkLine.contains("POIDS") &&
                           !checkLine.contains("UNITE") && !checkLine.contains("UNIT.") {
                            print("🔎 [STRAT4] Vérification ligne \(i+j): \(lines[i+j])")
                            if let amount = extractBestNumberFromLine(lines[i + j]) {
                                amountsAroundTotal.append(amount)
                            }
                        } else {
                            print("⏭️ [STRAT4] Ligne ignorée (contient poids/quantité): \(lines[i+j])")
                        }
                    }
                }
                
                if let maxAmount = amountsAroundTotal.max() {
                    print("💰 [STRAT4] Plus grand montant trouvé après 'Total': \(maxAmount)")
                    return maxAmount
                } else {
                    print("❌ [STRAT4] Aucun montant trouvé après 'Total'")
                }
            }
        }
        
        // 5th STRATEGY: Fallback - search max amount
        print("🔄 [STRAT5] Fallback - recherche avec filtres stricts")
        var allAmounts: [Double] = []
        for line in lines {
            let lineUpper = line.uppercased()
            if !lineUpper.contains("KG") && !lineUpper.contains("TN") &&
               !lineUpper.contains("QUANTITE") && !lineUpper.contains("POIDS") &&
               !lineUpper.contains("UNITE") && !lineUpper.contains("UNIT.") &&
               !lineUpper.contains("PRIX UNIT") && !lineUpper.contains("/TONNE") {
                if let amount = extractBestNumberFromLine(line) {
                    allAmounts.append(amount)
                    print("💰 [STRAT5] Montant trouvé: \(amount) dans ligne: \(line)")
                }
            } else {
                print("⏭️ [STRAT5] Ligne ignorée (contient poids/quantité): \(line)")
            }
        }
        
        if let maxAmount = allAmounts.max() {
            print("🏆 [STRAT5] Plus grand montant sélectionné: \(maxAmount)")
            return maxAmount
        } else {
            print("❌ [STRAT5] Aucun montant trouvé dans tout le document")
        }
        
        return nil
    }
    
    private func extractBestNumberFromLine(_ line: String) -> Double? {
        print("🔍 [HELPER] Analyse ligne: '\(line)'")
        
        // Number patterns
        let patterns = [
            "([0-9]\\s[0-9]{3},[0-9]{2})",    // "1 860,81" (format français avec espace)
            "([0-9]{1,3}\\s[0-9]{3},[0-9]{2})", // Variante
            "([0-9]+,[0-9]{2})",               // "1860,81" ou "79,00"
            "([0-9]+\\.[0-9]{2})",             // "1860.81"
        ]
        
        var foundNumbers: [Double] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(line.startIndex..., in: line)
                let matches = regex.matches(in: line, range: range)
                
                for match in matches {
                    if let matchRange = Range(match.range(at: 1), in: line) {
                        var numberStr = String(line[matchRange])
                        
                        // Nettoie
                        numberStr = numberStr.replacingOccurrences(of: " ", with: "")
                        numberStr = numberStr.replacingOccurrences(of: "\u{00A0}", with: "")
                        numberStr = numberStr.replacingOccurrences(of: ",", with: ".")
                        
                        if let value = Double(numberStr), value > 0 {
                            foundNumbers.append(value)
                            print("💰 [HELPER] Nombre extrait: '\(String(line[matchRange]))' -> \(value)")
                        }
                    }
                }
            }
        }
        
        if let maxNumber = foundNumbers.max() {
            print("🏆 [HELPER] Plus grand nombre sélectionné: \(maxNumber)")
            return maxNumber
        } else {
            print("❌ [HELPER] Aucun nombre trouvé dans cette ligne")
        }
        
        return nil
    }
    
    private func extractDate(from text: String) -> Date? {
        let datePatterns: [(pattern: String, formatter: DateFormatter)] = [
            // Pattern 1: "30 juin 2025" or "12 janvier 2026"
            ("([0-3]?[0-9])\\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\\s+([0-9]{4})", {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMMM yyyy"
                formatter.locale = Locale(identifier: "fr_FR")
                return formatter
            }()),
            
            // Pattern 2: DD/MM/YYYY or DD-MM-YYYY
            ("\\b([0-3]?[0-9])[/-]([0-1]?[0-9])[/-]([0-9]{4})\\b", {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                return formatter
            }()),
            
            // Pattern 3: "Date: 30/06/2025"
            ("(?i)date\\s*:?\\s*([0-3]?[0-9])[/-]([0-1]?[0-9])[/-]([0-9]{4})", {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                return formatter
            }())
        ]
        
        for (pattern, formatter) in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    // Format with month in letters
                    if pattern.contains("janvier") {
                        if let dateRange = Range(match.range, in: text) {
                            let dateStr = String(text[dateRange])
                            if let date = formatter.date(from: dateStr) {
                                return date
                            }
                        }
                    } else {
                        // Numeric format
                        if let dayRange = Range(match.range(at: 1), in: text),
                           let monthRange = Range(match.range(at: 2), in: text),
                           let yearRange = Range(match.range(at: 3), in: text) {
                            
                            let dateStr = "\(text[dayRange])/\(text[monthRange])/\(text[yearRange])"
                            if let date = formatter.date(from: dateStr) {
                                return date
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func saveBill() async {
        guard let amountDecimal = Decimal(string: amount),
              let categoryId = selectedCategoryId
        else {
            return
        }
        
        if selectedProviderId == nil {
            selectedProviderId = await detecteProviderId(name: providerName)
        }
        
        if shouldCreateProvider() {
            providerToCreate = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
            showProviderAlert = true
            return
        }
        do {
            let savedBill = try await viewModel.createBill(
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                providerId: selectedProviderId,
                providerName: providerName.isEmpty ? "" : providerName,
                comment: comment.isEmpty ? "" : comment
            )
            
            if let savedBill = savedBill {
                onSaved()
                if let message = viewModel.successMessage {
                    onSuccess(message)
                    dismiss()
                }
            }
        } catch {}
    }
    
    // Search an existing provider filtering on the given name
    private func detecteProviderId(name: String) async -> Int? {
        if let existingProvider = await viewModel.fetchProvider(name: name) {
            return existingProvider.id
        }
        return nil
    }
    
    private func shouldCreateProvider() -> Bool {
        let trimmedName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, selectedProviderId == nil else {
            return false
        }
        
        let providerExists = viewModel.providers.contains { provider in
            provider.name.lowercased() == trimmedName.lowercased()
        }
        
        return !providerExists
    }
    
    private func saveBillForceWithoutProvider() async {
        guard let amountDecimal = Decimal(string: amount),
              let categoryId = selectedCategoryId
        else {
            return
        }
        
        let providerId: Int? = nil
        
        do {
            let savedBill = try await viewModel.createBill(
                title: title,
                amount: amountDecimal,
                date: date,
                categoryId: categoryId,
                providerId: providerId,
                providerName: providerName.isEmpty ? "" : providerName,
                comment: comment.isEmpty ? "" : comment
            )
            
            if savedBill != nil {
                onSaved()
                if let message = viewModel.successMessage {
                    onSuccess(message)
                    dismiss()
                }
            }
        } catch {}
    }
    
    private func createNewProvider() async {
        let providerViewModel = ProviderFormViewModel()
        
        do {
            if let _ = try await providerViewModel.createProvider(name: providerToCreate) {
                await viewModel.loadProviders()
                
                if let createdProvider = viewModel.providers.first(where: { $0.name.lowercased() == providerToCreate.lowercased() }) {
                    selectedProviderId = createdProvider.id
                    providerName = createdProvider.name
                }
                
                
                await saveBill()
            }
        } catch {}
    }
}
#endif

