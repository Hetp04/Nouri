//
//  NouriCustomInputRow.swift
//  nouriapp
//

import SwiftUI

struct NouriCustomInputRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NouriColors.subtitle)
            
            // Input field
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(NouriColors.inputPlaceholder)
                        .padding(.leading, 12)
                }
                
                TextField("", text: $text)
                    .font(.system(size: 14))
                    .foregroundStyle(NouriColors.title)
                    .padding(.horizontal, 12)
            }
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(NouriColors.chipBorder, lineWidth: 1.5)
            )
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}
