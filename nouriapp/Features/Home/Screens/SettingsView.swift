//
//  SettingsView.swift
//  nouriapp
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var onboardingData: OnboardingData
    @StateObject private var socialAuth = SocialAuthManager.shared
    
    // Mock user data - in real app would come from a UserViewModel or SocialAuthManager
    let userName = "Het Patel" 
    let userEmail = "hpate384@gmail.com"
    let currentSubscription = "Free"
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 24) {
                    accountInfoSection
                    
                    settingsGroup(title: "Preferences") {
                        NavigationRow(icon: "person.text.rectangle", title: "Dietary Profile", subtitle: "Update allergies and concerns") {
                            // TODO: Add Dietary Profile Subview
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        NavigationRow(icon: "list.bullet.rectangle", title: "Ingredient Watchlist", subtitle: "Manage your red flags") {
                            // TODO: Add Watchlist Subview
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        NavigationRow(icon: "bookmark", title: "Manage Saved Products", subtitle: "0 saved meals for now") {
                            // TODO: Add Saved Products Subview
                        }
                    }
                    
                    settingsGroup(title: "Support") {
                        NavigationRow(icon: "envelope", title: "Contact Support") {
                            // TODO: Contact Support
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        NavigationRow(icon: "bubble.left.and.text.bubble.right", title: "Feedback") {
                            // TODO: Feedback
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        NavigationRow(icon: "trash", title: "Delete Account", titleColor: .red) {
                            // TODO: Delete Account
                        }
                    }
                    
                    signOutButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98)) // #F9FAFB
    }
    
    // MARK: - Subcomponents
    
    private var header: some View {
        ZStack {
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NouriColors.title)
            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(NouriColors.title)
                        .frame(width: 40, height: 40)
                        .background(NouriColors.iconBgColor, in: Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var subscriptionStatusText: String {
        currentSubscription == "Plus" ? "Nouri Plus" : "Trial Active"
    }

    private var accountInfoSection: some View {
        VStack(spacing: 0) {
            accountInfoRow(icon: "person", label: "Name") {
                standardValueText(userName.lowercased())
            }
            Divider().padding(.leading, 56)
            accountInfoRow(icon: "envelope", label: "Email") {
                standardValueText(userEmail)
            }
            Divider().padding(.leading, 56)
            accountInfoRow(icon: "plus.square.on.square", label: "Subscription") {
                if currentSubscription == "Plus" {
                    standardValueText(subscriptionStatusText)
                } else {
                    ShimmeringLabel(text: subscriptionStatusText)
                }
            }
            Divider().padding(.leading, 56)
            upgradeRow
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(NouriColors.divider, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }

    @ViewBuilder
    private func standardValueText(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(NouriColors.subtitle)
            .multilineTextAlignment(.trailing)
    }

    private func accountInfoRow<Content: View>(icon: String, label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(NouriColors.title.opacity(0.8))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(NouriColors.title)

            Spacer(minLength: 12)

            value()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var upgradeRow: some View {
        Button(action: {
            // TODO: Add Nouri Plus upgrade flow
        }) {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(NouriColors.title.opacity(0.8))
                    .frame(width: 24)

                Text(currentSubscription == "Plus" ? "Manage Nouri Plus" : "Go Plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(NouriColors.title)

                Spacer(minLength: 12)

                if currentSubscription == "Plus" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.2))
                } else {
                    Text("Upgrade")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 47 / 255, green: 107 / 255, blue: 79 / 255),
                                    Color(red: 82 / 255, green: 163 / 255, blue: 120 / 255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NouriColors.subtitle)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(NouriColors.divider, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            Task {
                await socialAuth.logout()
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Sign Out")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(red: 1, green: 0.95, blue: 0.95)) // #FFF1F1
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }
}

// MARK: - Row Helpers

struct NavigationRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = NouriColors.title
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(titleColor.opacity(0.7))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(titleColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(NouriColors.subtitle)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.2))
            }
            .padding(20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(NouriColors.title.opacity(0.7))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(NouriColors.title)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: NouriColors.brandGreen))
                .labelsHidden()
        }
        .padding(20)
    }
}

struct ShimmeringLabel: View {
    let text: String
    @State private var shimmerX: CGFloat = -120

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
            .overlay {
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.9), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 90)
                .offset(x: shimmerX)
                .mask(
                    Text(text)
                        .font(.system(size: 16, weight: .regular))
                )
            }
            .onAppear {
                shimmerX = -120
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    shimmerX = 120
                }
            }
    }
}

#Preview {
    SettingsView()
}
