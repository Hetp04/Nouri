//
//  ConcernsView.swift
//  nouriapp
//

import SwiftUI

struct ConcernsView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    @State private var anythingElse: String = ""
    @State private var selectedOptions: Set<String> = []

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "help",
                    title: "What do you care about?",
                    subtitle: "Select the topics that matter most to you",
                    accessibilityLabel: "Onion reading a book"
                )

                // Chips inside auto-wrapping FlowLayout
                FlowLayout(spacing: 8) {
                    NouriSelectableChip(id: "clean-eating", icon: "fork.knife", text: "Clean Eating", selection: $selectedOptions)
                    NouriSelectableChip(id: "acne-safe", icon: "drop", text: "Acne Safe", selection: $selectedOptions)
                    NouriSelectableChip(id: "weight-loss", icon: "figure.run", text: "Weight Loss", selection: $selectedOptions)
                    NouriSelectableChip(id: "kids-safe", icon: "face.smiling", text: "Kids Safe", selection: $selectedOptions)
                    NouriSelectableChip(id: "vegan", icon: "carrot", text: "Vegan", selection: $selectedOptions)
                    NouriSelectableChip(id: "high-protein", icon: "dumbbell", text: "High Protein", selection: $selectedOptions)
                    NouriSelectableChip(id: "low-sugar", icon: "cube", text: "Low Sugar", selection: $selectedOptions)
                    NouriSelectableChip(id: "heart-healthy", icon: "heart", text: "Heart Healthy", selection: $selectedOptions)
                    NouriSelectableChip(id: "organic", text: "Organic", imageName: "icons8-sprout", selectedImageName: "icons8-sprout 1", selection: $selectedOptions)
                    NouriSelectableChip(id: "non-gmo", icon: "checkmark.shield", text: "Non-GMO", selection: $selectedOptions)
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
                    placeholder: "e.g. Kosher",
                    text: $anythingElse
                )
            }
        }
    }
}

#Preview("Concerns") {
    ConcernsView()
}
