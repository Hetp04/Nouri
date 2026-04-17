//
//  EmailSignInViewModel.swift
//  nouriapp
//

import SwiftUI
import Combine

enum SignInPhase {
    case form
    case success
}

@MainActor
class EmailSignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    @Published var phase: SignInPhase = .form
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let auth = NouriAuth.shared
    
    func handleSignIn(onPhaseChange: @escaping () -> Void) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        do {
            let data = try await auth.signIn(email: normalizedEmail, password: password)
            
            // Extract access token from response for secure storage
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            let accessToken = json["access_token"] as? String ?? ""
            let refreshToken = json["refresh_token"] as? String ?? ""
            let userMeta = (json["user"] as? [String: Any])?["user_metadata"] as? [String: Any] ?? [:]
            let name = userMeta["full_name"] as? String ?? ""
            
            SocialAuthManager.shared.persistSession(
                email: normalizedEmail,
                name: name,
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            // Tie onboarding data to account securely avoiding redundant calls
            await auth.syncProfile(email: normalizedEmail)
            phase = .success
            onPhaseChange()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
