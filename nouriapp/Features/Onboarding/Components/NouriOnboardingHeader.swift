//
//  NouriOnboardingHeader.swift
//  nouriapp
//

import SwiftUI

struct NouriOnboardingHeader: View {
    let imageName: String
    let title: String
    let subtitle: String
    var accessibilityLabel: String? = nil
    var imageScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar image section
            HStack {
                Spacer()
                Image.bundled(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(imageScale)
                    .accessibilityLabel(accessibilityLabel ?? title)
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Title text
            Text(title)
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(NouriColors.title)
                .padding(.bottom, 6)
            
            // Subtitle text
            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(NouriColors.subtitle)
                .padding(.bottom, 16)
        }
    }
}
