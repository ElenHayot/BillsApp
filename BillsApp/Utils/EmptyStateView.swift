//
//  EmptyStateView.swift
//  BillsApp
//
//  Created by Elen Hayot on 08/01/2026.
//

import SwiftUI

struct EmptyStateView: View {
    
    let icon: String?
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    // ✅ Init avec tous les paramètres optionnels pour plus de flexibilité
    init(
        icon: String? = nil,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Icône optionnelle
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Bouton d'action optionnel
            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// ✅ Preview pour visualiser différents cas
#Preview("With action") {
    EmptyStateView(
        icon: "tag.slash",
        title: "Aucune catégorie",
        message: "Commence par créer au moins une catégorie pour organiser tes factures.",
        actionTitle: "Créer une catégorie",
        action: {
            print("Action!")
        }
    )
}

#Preview("Without action") {
    EmptyStateView(
        icon: "doc.text.magnifyingglass",
        title: "Aucune facture",
        message: "Il n'y a pas encore de factures pour cette période."
    )
}

#Preview("Without icon") {
    EmptyStateView(
        title: "Aucun résultat",
        message: "Essayez de modifier vos critères de recherche."
    )
}
