//
//  AllergiesView.swift
//  nouriapp
//

import SwiftUI

struct AllergiesView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    
    @EnvironmentObject var onboardingData: OnboardingData
    
    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "allergy",
                    title: OnboardingCopy.Allergies.title,
                    subtitle: OnboardingCopy.Allergies.subtitle,
                    accessibilityLabel: OnboardingCopy.Allergies.accessibilityLabel
                )
                
                FlowLayout(spacing: 8) {
                    ForEach(TopicRegistry.allergies, id: \.id) { topic in
                        NouriSelectableChip(
                            id: topic.id,
                            icon: topic.icon,
                            text: topic.text,
                            imageName: topic.imageName,
                            selectedImageName: topic.selectedImageName,
                            selection: $onboardingData.allergies
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
                    title: OnboardingCopy.Allergies.customInputTitle,
                    placeholder: OnboardingCopy.Allergies.customInputPlaceholder,
                    text: $onboardingData.otherAllergies
                )
                
                // Disclaimer / Quick Tip
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(NouriColors.tipIcon)
                    
                    Text(OnboardingCopy.Allergies.disclaimerText)
                        .font(.system(size: 13, weight: .medium))
                        .lineSpacing(4)
                        .foregroundStyle(NouriColors.subtitle)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NouriColors.tipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(NouriColors.tipIcon.opacity(0.15), lineWidth: 1)
                )
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview("Allergies") {
    AllergiesView()
        .environmentObject(OnboardingData.shared)
}
