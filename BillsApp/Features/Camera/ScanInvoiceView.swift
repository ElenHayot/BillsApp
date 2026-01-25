//
//  ScanBillView.swift
//  BillsApp
//
//  Created by Elen Hayot on 22/01/2026.
//

import Foundation
import SwiftUI

#if os(iOS)
struct ScanInvoiceView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }
            
            Button("Scanner une facture") {
                showCamera = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
    }
}
#endif
