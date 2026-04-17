//
//  TempDashboardView.swift
//  nouriapp
//

import SwiftUI

struct TempDashboardView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var isLoggingOut = false
    
    // Read user info from Keychain (secure) instead of UserDefaults (plain text)
    private var userEmail: String { KeychainManager.read(key: KeychainManager.userEmailKey) ?? "" }
    private var userName: String { KeychainManager.read(key: KeychainManager.userNameKey) ?? "" }
    
    var body: some View {
        VStack(spacing: 24) {
            Image.bundled("signup")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text("Hi \(userName.isEmpty ? "there" : userName) 👋")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(NouriColors.title)
            
            Text("You are successfully logged in with:\n\(userEmail)")
                .font(.system(size: 16))
                .foregroundStyle(NouriColors.subtitle)
                .multilineTextAlignment(.center)
            
            Button(action: {
                isLoggingOut = true
                Task {
                    // Proper logout: invalidate server session + clear Keychain + clear flag
                    await SocialAuthManager.shared.logout()
                    isLoggingOut = false
                }
            }) {
                if isLoggingOut {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(NouriColors.brandGreen.opacity(0.7))
                        .clipShape(Capsule())
                } else {
                    Text("Log Out")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(NouriColors.brandGreen)
                        .clipShape(Capsule())
                }
            }
            .disabled(isLoggingOut)
            .padding(.horizontal, 40)
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NouriColors.canvas.ignoresSafeArea())
    }
}

#Preview {
    TempDashboardView()
}
