//
//  ConcernsView.swift
//  nouriapp
//

import SwiftUI

struct ConcernsView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    @EnvironmentObject var onboardingData: OnboardingData

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "help",
                    title: OnboardingCopy.Concerns.title,
                    subtitle: OnboardingCopy.Concerns.subtitle,
                    accessibilityLabel: OnboardingCopy.Concerns.accessibilityLabel
                )

                // Chips inside auto-wrapping FlowLayout
                FlowLayout(spacing: 8) {
                    ForEach(TopicRegistry.concerns, id: \.id) { topic in
                        NouriSelectableChip(
                            id: topic.id,
                            icon: topic.icon,
                            text: topic.text,
                            imageName: topic.imageName,
                            selectedImageName: topic.selectedImageName,
                            selection: $onboardingData.concerns
                        )
                    }
                }
                .padding(.bottom, 20)
                
                // Divider + custom input
                Rectangle()
                    .fill(NouriColors.divider)
                    .frame(height: 1)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                
                NouriCustomInputRow(
                    title: OnboardingCopy.Concerns.customInputTitle,
                    placeholder: OnboardingCopy.Concerns.customInputPlaceholder,
                    text: $onboardingData.otherConcerns
                )
            }
        }
    }
}

#Preview("Concerns") {
    ConcernsView()
        .environmentObject(OnboardingData.shared)
}
