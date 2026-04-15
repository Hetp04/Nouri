//
//  AllergiesView.swift
//  nouriapp
//

import SwiftUI

struct AllergiesView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    
    @State private var customAllergy: String = ""
    @State private var selectedAllergies: Set<String> = []
    
    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "allergy",
                    title: "Any allergies?",
                    subtitle: "We'll filter recipes to ensure they're safe for you.",
                    accessibilityLabel: "Onion with allergy"
                )
                
                FlowLayout(spacing: 8) {
                    NouriSelectableChip(id: "shellfish", icon: "fish", text: "Shellfish", selection: $selectedAllergies)
                    NouriSelectableChip(id: "eggs", text: "Eggs", imageName: "icons8-eggs", selectedImageName: "icons8-eggs 1", selection: $selectedAllergies)
                    NouriSelectableChip(id: "milk", text: "Milk", imageName: "icons8-milk", selectedImageName: "icons8-milk 1", selection: $selectedAllergies)
                    NouriSelectableChip(id: "soy", text: "Soy", imageName: "soy", selectedImageName: "soyFlip", selection: $selectedAllergies)
                    NouriSelectableChip(id: "gluten", icon: "leaf", text: "Gluten", selection: $selectedAllergies)
                    NouriSelectableChip(id: "nuts", text: "Nuts", imageName: "icons8-nuts", selectedImageName: "icons8-hazelnut", selection: $selectedAllergies)
                    NouriSelectableChip(id: "sesame", text: "Sesame", imageName: "icons8-seed-packet", selectedImageName: "icons8-seed-packet 1", selection: $selectedAllergies)
                    NouriSelectableChip(id: "wheat", text: "Wheat", imageName: "icons8-wheat", selection: $selectedAllergies)
                    NouriSelectableChip(id: "corn", text: "Corn", imageName: "icons8-corn", selectedImageName: "icons8-corn 1", selection: $selectedAllergies)
                }
                .padding(.bottom, 20)
                
                // Divider + custom input
                Rectangle()
                    .fill(NouriColors.divider)
                    .frame(height: 1)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                
                NouriCustomInputRow(
                    title: "Anything else? (optional)",
                    placeholder: "e.g. Mustard",
                    text: $customAllergy
                )
                
                // Disclaimer / Quick Tip
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(NouriColors.tipIcon)
                    
                    Text("Nouri provides guidance based on ingredients, but please always verify labels for severe allergies.")
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
}
