//
//  SocialAuthManager.swift
//  nouriapp
//
//  Handles Sign in with Apple (native) and Sign in with Google (Supabase OAuth via ASWebAuthenticationSession).
//

import AuthenticationServices
import SwiftUI
import Combine

@MainActor
class SocialAuthManager: NSObject, ObservableObject {
    static let shared = SocialAuthManager()
    private override init() {}

    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    // For OTP after social login
    @Published var showSocialOTP = false
    @Published var pendingSocialUser: SupabaseUser?
    @Published var socialOTPResendSecs = 0
    @Published var canResendSocialOTP = true
    
    private var resendTimerTask: Task<Void, Never>?
    
    // MARK: - Session Management
    
    /// Persists session securely in Keychain + sets AppStorage flag for reactive UI.
    func persistSession(email: String, name: String, accessToken: String = "", refreshToken: String = "") {
        // Secure storage (encrypted)
        KeychainManager.saveSession(
            email: email,
            name: name,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        // AppStorage flag for reactive SwiftUI — only a boolean, no sensitive data
        UserDefaults.standard.set(true, forKey: NouriConfig.Constants.isLoggedInKey)
    }
    
    /// Clears all session data (Keychain + UserDefaults) and notifies Supabase.
    func logout() async {
        // 1. Tell Supabase to invalidate the session server-side
        if let token = KeychainManager.read(key: KeychainManager.accessTokenKey) {
            try? await NouriAuth.shared.signOut(accessToken: token)
        }
        
        // 2. Clear secure storage
        KeychainManager.clearSession()
        
        // 3. Clear the UI flag
        UserDefaults.standard.set(false, forKey: NouriConfig.Constants.isLoggedInKey)
        
        // 4. Reset onboarding state for the next user
        OnboardingData.shared.concerns = []
        OnboardingData.shared.otherConcerns = ""
        OnboardingData.shared.allergies = []
        OnboardingData.shared.otherAllergies = ""
        OnboardingData.shared.shoppingCategories = []
        OnboardingData.shared.otherShopping = ""
        OnboardingData.shared.processLevel = OnboardingData.defaultProcessLevel
        OnboardingData.shared.calorieGoal = OnboardingData.defaultCalorieGoal
        OnboardingData.shared.wasOnboarded = false
    }
    
    /// Validates the current session with Supabase. Returns false if session is invalid.
    func validateSession() async -> Bool {
        guard let token = KeychainManager.read(key: KeychainManager.accessTokenKey),
              !token.isEmpty else {
            return false
        }
        
        do {
            let user = try await NouriAuth.shared.fetchUser(accessToken: token)
            await NouriAuth.shared.syncProfile(email: user.email)
            return true
        } catch {
            // Token is expired or user was deleted — clear local session
            KeychainManager.clearSession()
            UserDefaults.standard.set(false, forKey: NouriConfig.Constants.isLoggedInKey)
            return false
        }
    }
    
    /// Determines whether a social-login user still needs OTP verification.
    /// Checks the email_verifications table — the single source of truth.
    /// A DB trigger on auth.users automatically cleans up stale rows on deletion.
    private func needsVerification(user: SupabaseUser) async -> Bool {
        let alreadyVerified = await NouriAuth.shared.isEmailVerified(email: user.email)
        return !alreadyVerified
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Google Sign In (via Supabase OAuth + ASWebAuthenticationSession)
    
    func signInWithGoogle() {
        guard var components = URLComponents(string: "\(NouriConfig.supabaseURL)/auth/v1/authorize") else { return }
        components.queryItems = [
            URLQueryItem(name: "provider",    value: "google"),
            URLQueryItem(name: "redirect_to", value: NouriConfig.Constants.googleRedirectURI),
        ]
        guard let authURL = components.url else { return }
        
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "nouri-app"
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            
            if let error {
                Task { @MainActor in
                    // Ignore user cancellation
                    if (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
                        self.errorMessage = error.localizedDescription
                    }
                }
                return
            }
            
            guard let callbackURL else { return }
            Task { @MainActor in await self.handleGoogleCallback(url: callbackURL) }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    func handleGoogleCallback(url: URL) async {
        let rawFragment = url.fragment ?? ""
        let rawQuery    = url.query    ?? ""
        let source      = rawFragment.isEmpty ? rawQuery : rawFragment
        
        var params: [String: String] = [:]
        source.components(separatedBy: "&").forEach { pair in
            let kv = pair.components(separatedBy: "=")
            if kv.count == 2 { params[kv[0]] = kv[1].removingPercentEncoding }
        }
        
        guard let accessToken = params["access_token"] else {
            errorMessage = "Google sign-in failed: no token received."
            return
        }
        
        let refreshToken = params["refresh_token"] ?? ""
        
        do {
            isLoading = true
            let user = try await NouriAuth.shared.fetchUser(accessToken: accessToken)
            
            if await needsVerification(user: user) {
                // New or unverified user: send OTP
                try await NouriAuth.shared.resendOTP(email: user.email)
                pendingSocialUser = user
                // Store tokens temporarily so we can persist them after OTP
                KeychainManager.save(key: KeychainManager.accessTokenKey, value: accessToken)
                KeychainManager.save(key: KeychainManager.refreshTokenKey, value: refreshToken)
                showSocialOTP = true
                startResendTimer()
            } else {
                // Returning verified user: skip OTP
                persistSession(email: user.email, name: user.name, accessToken: accessToken, refreshToken: refreshToken)
                await NouriAuth.shared.syncProfile(email: user.email)
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Social OTP
    
    func verifySocialOTP(code: String) async {
        guard let user = pendingSocialUser else { return }
        isLoading = true
        errorMessage = ""
        
        do {
            try await NouriAuth.shared.verifySocialOTP(email: user.email, code: code)
            
            // Tokens were stored temporarily during the social login
            let accessToken = KeychainManager.read(key: KeychainManager.accessTokenKey) ?? ""
            let refreshToken = KeychainManager.read(key: KeychainManager.refreshTokenKey) ?? ""
            
            persistSession(email: user.email, name: user.name, accessToken: accessToken, refreshToken: refreshToken)
            await NouriAuth.shared.syncProfile(email: user.email)
            
            resendTimerTask?.cancel()
            showSocialOTP = false
            pendingSocialUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func resendSocialOTP() async {
        guard let user = pendingSocialUser else { return }
        errorMessage = ""
        
        do {
            try await NouriAuth.shared.resendOTP(email: user.email)
            startResendTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func startResendTimer() {
        resendTimerTask?.cancel()
        socialOTPResendSecs = 60
        canResendSocialOTP = false
        
        resendTimerTask = Task {
            for i in stride(from: 60, through: 1, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                socialOTPResendSecs = i - 1
            }
            canResendSocialOTP = true
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate (Apple)
extension SocialAuthManager: ASAuthorizationControllerDelegate {
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData   = credential.identityToken,
              let idToken     = String(data: tokenData, encoding: .utf8) else { return }
        
        let firstName = credential.fullName?.givenName  ?? ""
        let lastName  = credential.fullName?.familyName ?? ""
        let fullName  = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        Task { @MainActor in
            do {
                self.isLoading = true
                let user = try await NouriAuth.shared.signInWithApple(idToken: idToken, fullName: fullName)
                
                if await self.needsVerification(user: user) {
                    try await NouriAuth.shared.resendOTP(email: user.email)
                    self.pendingSocialUser = user
                    self.showSocialOTP = true
                    self.startResendTimer()
                } else {
                    self.persistSession(email: user.email, name: user.name)
                    await NouriAuth.shared.syncProfile(email: user.email)
                }
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // User cancelled — no error shown for cancellation
        guard (error as? ASAuthorizationError)?.code != .canceled else { return }
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Presentation Context Providers
extension SocialAuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

extension SocialAuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Convenience struct for user info returned from Supabase
struct SupabaseUser {
    let email: String
    let name: String
}
