//
//  WelcomeView.swift
//  nouriapp
//

import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void = {}
    var onSignIn: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Header Logo
                HStack {
                    Image.bundled("nouri")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .accessibilityLabel("Nouri logo")
                    Spacer(minLength: 0)
                }
                .offset(y: -24)

                Spacer(minLength: 0)

                // Main Content
                VStack(spacing: 0) {
                    Image.bundled("splash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .accessibilityLabel("Nouri avatar")

                    Text("Welcome to Nouri")
                        .font(.system(size: 36, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(NouriColors.title)
                        .multilineTextAlignment(.center)

                    subtitle
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 10)
                        .padding(.horizontal, 8)
                }

                Spacer(minLength: 0)

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onGetStarted()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(0.1)
                            .foregroundStyle(NouriColors.primaryButtonLabel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(NouriColors.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .medium), trigger: true)

                    Button {
                        onSignIn()
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(NouriColors.secondaryLabel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(NouriColors.secondaryStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .medium), trigger: true)
                }
            }
            .padding(.horizontal, 28)
        .padding(.top, 40)
        .padding(.bottom, 28)
    }

    private var subtitle: Text {
        Text("Understand ingredients instantly.\nMake ").foregroundStyle(NouriColors.subtitle)
            + Text("healthier choices")
            .foregroundStyle(NouriColors.brandGreen)
            .fontWeight(.semibold)
            + Text(" effortlessly.").foregroundStyle(NouriColors.subtitle)
    }
}

#Preview("Welcome") {
    WelcomeView()
}
