//
//  NouriOnboardingWrapper.swift
//  nouriapp
//

import SwiftUI

struct NouriOnboardingWrapper<Content: View>: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    var nextButtonLabel: String = "Next"

    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                // Outer padding is controlled by the wrapper
                content
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical) // Remove bounce if content is small
            
            NouriOnboardingFooter(
                onBack: onBack,
                onNext: onNext,
                nextButtonLabel: nextButtonLabel
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
