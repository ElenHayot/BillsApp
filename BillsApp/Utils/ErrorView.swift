//
//  ErrorView.swift
//  BillsApp
//
//  Created by Elen Hayot on 13/01/2026.
//

import SwiftUI

struct ErrorView: View {

    let message: String
    let retryAction: (() -> Void)?

    init(
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Une erreur est survenue")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("Réessayer", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(maxWidth: 400)
    }
}
