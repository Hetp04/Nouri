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

    @State private var selectedOptions: Set<String> = []
    @State private var anythingElse: String = ""

    // Shopping categories mapped from SHOPPING_OPTIONS in the RN source
    private let options: [(id: String, icon: String, label: String)] = [
        ("meat-seafood",  "fish",           "Meat/Seafood"),
        ("supplements",   "flask",          "Supplements"),
        ("snacks",        "popcorn",        "Snacks"),
        ("dairy-eggs",    "oval",           "Dairy/Eggs"),
        ("produce",       "leaf",           "Produce"),
        ("frozen",        "snowflake",      "Frozen"),
        ("pantry",        "archivebox",     "Pantry"),
        ("beverages",     "cup.and.saucer", "Beverages"),
    ]

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "cart",
                    title: "What do you shop for the most?",
                    subtitle: "Select the categories you buy most often.",
                    accessibilityLabel: "Shopping cart illustration",
                    imageScale: 1.25
                )

                // Chips inside FlowLayout array iteration
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.id) { opt in
                        if opt.id == "supplements" {
                            NouriSelectableChip(id: opt.id, text: opt.label, imageName: "icons8-pill", selectedImageName: "icons8-pill 1", selection: $selectedOptions)
                        } else if opt.id == "produce" {
                            NouriSelectableChip(id: opt.id, text: opt.label, imageName: "icons8-vegetable", selectedImageName: "icons8-broccoli", selection: $selectedOptions)
                        } else {
                            NouriSelectableChip(id: opt.id, icon: opt.icon, text: opt.label, selection: $selectedOptions)
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
                    title: "Anything else? (optional)",
                    placeholder: "e.g. Kosher options",
                    text: $anythingElse
                )
            }
        }
    }
}

#Preview("Shopping") {
    ShoppingView()
}
