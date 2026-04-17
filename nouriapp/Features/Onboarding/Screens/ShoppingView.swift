//
//  ShoppingView.swift
//  nouriapp
//
//  Step 3/5 — What do you shop for most?
//

import SwiftUI

struct ShoppingView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    @EnvironmentObject var onboardingData: OnboardingData

    // Shopping categories mapped from SHOPPING_OPTIONS in the RN source


    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "cart",
                    title: OnboardingCopy.Shopping.title,
                    subtitle: OnboardingCopy.Shopping.subtitle,
                    accessibilityLabel: OnboardingCopy.Shopping.accessibilityLabel,
                    imageScale: 1.25
                )

                // Chips inside FlowLayout array iteration
                FlowLayout(spacing: 8) {
                    ForEach(TopicRegistry.shopping, id: \.id) { opt in
                        if let img = opt.imageName {
                            NouriSelectableChip(
                                id: opt.id,
                                text: opt.text,
                                imageName: img,
                                selectedImageName: opt.selectedImageName,
                                selection: $onboardingData.shoppingCategories
                            )
                        } else {
                            NouriSelectableChip(
                                id: opt.id,
                                icon: opt.icon,
                                text: opt.text,
                                selection: $onboardingData.shoppingCategories
                            )
                        }
                    }
                }
                .padding(.bottom, 20)

                // Divider
                Rectangle()
                    .fill(NouriColors.divider)
                    .frame(height: 1)
                    .padding(.top, 4)

                NouriCustomInputRow(
                    title: OnboardingCopy.Shopping.customInputTitle,
                    placeholder: OnboardingCopy.Shopping.customInputPlaceholder,
                    text: $onboardingData.otherShopping
                )
            }
        }
    }
}

#Preview("Shopping") {
    ShoppingView()
        .environmentObject(OnboardingData.shared)
}
