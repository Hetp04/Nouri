//
//  FactsView.swift
//  nouriapp
//

import SwiftUI

struct FoodFact: Identifiable {
    let id: String
    let title: String
    let content: String
    let gifName: String   // animated GIF from bundle
}

struct FactsView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    // GIF names match RN source exactly: diabetes, flask, bpa-free, dropper
    private let facts = [
        FoodFact(id: "sugar",   title: OnboardingCopy.Facts.sugarTitle,    content: OnboardingCopy.Facts.sugarContent, gifName: "diabetes"),
        FoodFact(id: "natural", title: OnboardingCopy.Facts.naturalTitle,   content: OnboardingCopy.Facts.naturalContent,        gifName: "flask"),
        FoodFact(id: "labels",  title: OnboardingCopy.Facts.labelsTitle,     content: OnboardingCopy.Facts.labelsContent,                 gifName: "bpa-free"),
        FoodFact(id: "dye",     title: OnboardingCopy.Facts.dyeTitle,            content: OnboardingCopy.Facts.dyeContent,            gifName: "dropper"),
    ]

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext, nextButtonLabel: "Next") {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "facts",
                    title: OnboardingCopy.Facts.title,
                    subtitle: OnboardingCopy.Facts.subtitle,
                    accessibilityLabel: OnboardingCopy.Facts.accessibilityLabel,
                    imageScale: 1.1
                )

                // Facts List
                VStack(spacing: 12) {
                    ForEach(Array(facts.enumerated()), id: \.element.id) { index, fact in
                        FactRow(fact: fact, index: index)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

private struct FactRow: View {
    let fact: FoodFact
    let index: Int
    @State private var appeared = false

    // Light grey card background matching the RN design
    private let cardBg = Color(red: 247/255, green: 248/255, blue: 250/255)

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // GIF icon inside a white circle on grey card
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)

                AnimatedGIFImage(name: fact.gifName, size: 36)
                    .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fact.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(NouriColors.title)

                Text(fact.content)
                    .font(.system(size: 13))
                    .foregroundStyle(NouriColors.subtitle)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(Double(index) * 0.08)) {
                appeared = true
            }
        }
    }
}

#Preview("Facts") {
    FactsView()
}
