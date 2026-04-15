//
//  QuickTipView.swift
//  nouriapp
//

import SwiftUI

struct QuickTipView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 24) {
                NouriOnboardingHeader(
                    imageName: "sprout", // You can change this to a specific tip graphic!
                    title: "Quick Tip",
                    subtitle: "A helpful guide for your journey.",
                    accessibilityLabel: "Quick tip avatar"
                )
                
                // Placeholder for actual tips
                VStack(spacing: 16) {
                    Text("This is an empty placeholder screen for the quick tip.")
                        .font(.system(size: 16))
                        .foregroundStyle(NouriColors.subtitle)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 8)
                
            }
        }
    }
}

#Preview {
    QuickTipView()
}
