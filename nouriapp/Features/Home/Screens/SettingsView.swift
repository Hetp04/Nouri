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
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 24) {
                    profileSection
                    
                    settingsGroup(title: "Preferences") {
                        NavigationRow(icon: "person.text.rectangle", title: "Dietary Profile", subtitle: "Update allergies and concerns") {
                            // TODO: Add Dietary Profile Subview
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        NavigationRow(icon: "list.bullet.rectangle", title: "Ingredient Watchlist", subtitle: "Manage your red flags") {
                            // TODO: Add Watchlist Subview
                        }
                    }
                    
                    settingsGroup(title: "Support") {
                        NavigationRow(icon: "envelope", title: "Contact Support") {
                            // TODO: Contact Support
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
    
    private var profileSection: some View {
        HStack(spacing: 16) {
            // Avatar Placeholder
            Circle()
                .fill(NouriColors.brandGreen.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(userName.prefix(1))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(NouriColors.brandGreen)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(NouriColors.title)
                
                Text(userEmail)
                    .font(.system(size: 14))
                    .foregroundStyle(NouriColors.subtitle)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(NouriColors.divider, lineWidth: 1)
        )
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

#Preview {
    SettingsView()
}
