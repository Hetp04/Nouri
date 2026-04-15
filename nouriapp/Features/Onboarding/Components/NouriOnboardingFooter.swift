//
//  NouriOnboardingFooter.swift
//  nouriapp
//

import SwiftUI

struct NouriOnboardingFooter: View {
    var onBack: () -> Void
    var onNext: () -> Void
    var isNextEnabled: Bool = true
    var nextButtonLabel: String = "Next"
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(NouriColors.title)
                    .frame(width: 52, height: 52)
                    .background(NouriColors.backButtonBg)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Next button
            Button(action: onNext) {
                Text(nextButtonLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isNextEnabled ? NouriColors.brandGreen : NouriColors.disabledButton)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.2), value: isNextEnabled)
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled)
            .sensoryFeedback(.impact(weight: .medium), trigger: true)
        }
        .padding(.top, 12)
    }
}
