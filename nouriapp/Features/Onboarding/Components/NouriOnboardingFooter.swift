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
        ZStack {
            // Main Next Button Area
            Button(action: onNext) {
                HStack {
                    Spacer()
                    Text(nextButtonLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.leading, 32) // Balance the back button visual weight
                    Spacer()
                }
                .frame(height: 56)
                .background(isNextEnabled ? NouriColors.brandGreen : NouriColors.disabledButton)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled)
            .sensoryFeedback(.impact(weight: .medium), trigger: isNextEnabled)
            
            // Nested Back Button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isNextEnabled ? NouriColors.brandGreen : .gray)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.leading, 6)
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isNextEnabled)
        .padding(.top, 12)
    }
}
