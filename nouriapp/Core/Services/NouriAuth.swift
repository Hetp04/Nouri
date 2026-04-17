//
//  NouriAuth.swift
//  nouriapp
//

import Foundation

enum AuthError: LocalizedError {
    case server(String), invalidOTP, sessionExpired
    var errorDescription: String? {
        switch self {
        case .server(let msg):  return msg
        case .invalidOTP:       return "Invalid or expired code."
        case .sessionExpired:   return "Session expired. Sign up again."
        }
    }
}

// MARK: - Email Templates
enum EmailTemplate {
    static func verificationHTML(name: String, code: String) -> String {
        return "<h2>Verify your email</h2><p>Hi \(name.isEmpty ? "there" : name),</p><p>Your code is: <b>\(code)</b></p>"
    }
}

actor NouriAuth {
    static let shared = NouriAuth()
    private init() {}

    private var pending: [String: (password: String, name: String)] = [[:] as! [String: (password: String, name: String)]].first! // Simplified initialization for a dictionary

    // Note: Re-initializing for clarity
    private var users: [String: (password: String, name: String)] = [:]

    // MARK: - Public API

    @discardableResult
    func signIn(email: String, password: String) async throws -> Data {
        let e = normalize(email)
        return try await request(path: NouriConfig.Path.authSignIn, body: ["email": e, "password": password])
    }

    /// Invalidate the session on Supabase's servers.
    func signOut(accessToken: String) async throws {
        try await request(
            path: NouriConfig.Path.authLogout,
            body: [:],
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }

    /// Exchange an Apple ID token for a Supabase session.
    func signInWithApple(idToken: String, fullName: String) async throws -> SupabaseUser {
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken
        ]
        let data = try await request(path: NouriConfig.Path.authIdToken, body: body)
        return try decodeUser(from: data, fallbackName: fullName)
    }

    /// Fetch the authenticated user's profile using a Supabase access token.
    func fetchUser(accessToken: String) async throws -> SupabaseUser {
        let data = try await request(
            path: NouriConfig.Path.authUser,
            method: "GET",
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
        return try decodeUser(from: data, fallbackName: "")
    }

    func signUp(email: String, password: String, name: String) async throws {
        let e = normalize(email)
        users[e] = (password, name)

        // 1. Create User
        try await request(path: NouriConfig.Path.authSignUp, body: ["email": email, "password": password, "data": ["full_name": name]])

        // 2. Setup DB & Email (Sequential for simplicity and safety)
        let code = String(format: "%06d", Int.random(in: 100_000...999_999))
        let expires = ISO8601DateFormatter().string(from: Date().addingTimeInterval(600))
        
        try await upsert(table: "email_verifications", body: ["email": e, "verified": false])
        try await upsert(table: "otp_codes", body: ["email": e, "code": code, "expires_at": expires])
        try await sendEmail(to: e, code: code, name: name)
    }

    func verifyOTP(email: String, code: String) async throws {
        let e = normalize(email)
        let now = ISO8601DateFormatter().string(from: Date())
        let path = "\(NouriConfig.Path.restOTP)?email=eq.\(e)&code=eq.\(code)&expires_at=gt.\(now)&select=email"
        
        let data = try await request(path: path, method: "GET")
        let matches = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        guard (matches?.count ?? 0) > 0 else { throw AuthError.invalidOTP }
        
        try await request(path: "\(NouriConfig.Path.restOTP)?email=eq.\(e)", method: "DELETE")
        try await upsert(table: "email_verifications", body: ["email": e, "verified": true, "verified_at": now])

        guard let creds = users[e] else { throw AuthError.sessionExpired }
        try await request(path: NouriConfig.Path.authSignIn, body: ["email": e, "password": creds.password])
        users.removeValue(forKey: e)
    }

    func resendOTP(email: String) async throws {
        let e = normalize(email)
        let name = users[e]?.name ?? ""
        let code = String(format: "%06d", Int.random(in: 100_000...999_999))
        let expires = ISO8601DateFormatter().string(from: Date().addingTimeInterval(600))
        
        // Ensure the email_verifications row exists (unverified) for new social users
        try await upsert(table: "email_verifications", body: ["email": e, "verified": false])
        try await upsert(table: "otp_codes", body: ["email": e, "code": code, "expires_at": expires])
        try await sendEmail(to: e, code: code, name: name)
    }

    /// Check if this email has already been verified in the email_verifications table.
    func isEmailVerified(email: String) async -> Bool {
        let e = normalize(email)
        let path = "\(NouriConfig.Path.restVerify)?email=eq.\(e)&verified=eq.true&select=email"
        do {
            let data = try await request(path: path, method: "GET")
            let matches = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
            return (matches?.count ?? 0) > 0
        } catch {
            return false
        }
    }

    /// Verifies OTP for social login (where we don't have/need a password yet).
    func verifySocialOTP(email: String, code: String) async throws {
        let e = normalize(email)
        let now = ISO8601DateFormatter().string(from: Date())
        let path = "\(NouriConfig.Path.restOTP)?email=eq.\(e)&code=eq.\(code)&expires_at=gt.\(now)&select=email"
        
        let data = try await request(path: path, method: "GET")
        let matches = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        guard (matches?.count ?? 0) > 0 else { throw AuthError.invalidOTP }
        
        // Clean up
        try await request(path: "\(NouriConfig.Path.restOTP)?email=eq.\(e)", method: "DELETE")
        try await upsert(table: "email_verifications", body: ["email": e, "verified": true, "verified_at": now])
    }

    /// Synchronizes the user's local onboarding state with their remote Supabase profile.
    /// This handles conflicting states and completely eliminates redundant network calls.
    func syncProfile(email: String) async {
        let e = normalize(email)
        // Read local state synchronously on MainActor
        let (hasLocalData, savedDictionary) = await MainActor.run {
            let hasSelection = OnboardingData.shared.wasOnboarded && OnboardingData.shared.hasSelections
            return (hasSelection, OnboardingData.shared.toDictionary())
        }
        
        let path = "\(NouriConfig.Path.restProfiles)?email=eq.\(e)&select=*"
        
        do {
            let data = try await request(path: path, method: "GET")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let profiles = try decoder.decode([UserProfileDTO].self, from: data)
            
            if let remoteProfile = profiles.first {
                // 1. Profile exists remotely
                if hasLocalData {
                    // Conflict: User made local selections but also has a remote profile.
                    print("⚠️ [NouriAuth] Conflict: Remote profile exists but local data is also present for \(e)")
                    await MainActor.run {
                        OnboardingData.shared.pendingEmail = e
                        OnboardingData.shared.showConflictAlert = true
                    }
                } else {
                    // Clean Login / Launch: Just load remote data into local state.
                    await MainActor.run {
                        OnboardingData.shared.update(from: remoteProfile)
                    }
                    print("✅ [NouriAuth] Loaded remote profile into local state for \(e)")
                }
            } else {
                // 2. No remote profile exists
                if hasLocalData {
                    // Commit local offline onboarding to the server.
                    print("🚀 [NouriAuth] Pushing initial offline onboarding to remote for \(e)")
                    await saveOnboardingData(email: e, data: savedDictionary)
                } else {
                    print("ℹ️ [NouriAuth] No remote profile and no local data for \(e)")
                }
            }
        } catch {
            print("❌ [NouriAuth] Profile sync failed for \(e): \(error.localizedDescription)")
        }
    }
    
    func saveOnboardingData(email: String, data: [String: Any]) async {
        let e = normalize(email)
        do {
            var body = data
            body["email"] = e
            body["updated_at"] = ISO8601DateFormatter().string(from: Date())
            
            try await upsert(table: "user_profiles", body: body)
            print("✅ [NouriAuth] Onboarding data saved successfully for \(e)")
        } catch {
            print("❌ [NouriAuth] Failed to save onboarding data for \(e): \(error.localizedDescription)")
        }
    }

    // MARK: - Private Core

    @discardableResult
    private func request(path: String, method: String = "POST", body: [String: Any]? = nil, headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: (path.hasPrefix("http") ? "" : NouriConfig.supabaseURL) + path) else { throw AuthError.server("URL Error") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(NouriConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(NouriConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        if let body = body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        
        let (data, res) = try await URLSession.shared.data(for: req)
        if let http = res as? HTTPURLResponse, http.statusCode >= 400 {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw AuthError.server(json?["message"] as? String ?? json?["msg"] as? String ?? "Error")
        }
        return data
    }

    private func upsert(table: String, body: [String: Any]) async throws {
        try await request(path: "/rest/v1/\(table)?on_conflict=email", body: body, headers: ["Prefer": "resolution=merge-duplicates"])
    }

    private func sendEmail(to email: String, code: String, name: String) async throws {
        let html = EmailTemplate.verificationHTML(name: name, code: code)
        let body = ["from": NouriConfig.resendFromEmail, "to": email, "subject": "Verify your email – Nouri", "html": html]
        
        guard let url = URL(string: NouriConfig.Constants.resendApiURL) else { throw AuthError.server("URL Error") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(NouriConfig.resendKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: req)
    }

    private func normalize(_ email: String) -> String { email.lowercased().trimmingCharacters(in: .whitespaces) }

    /// Decode email and display_name / full_name from a Supabase auth response.
    private func decodeUser(from data: Data, fallbackName: String) throws -> SupabaseUser {
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        
        let userDict = (json["user"] as? [String: Any]) ?? json
        
        let email = userDict["email"] as? String ?? ""
        let meta  = (userDict["user_metadata"] as? [String: Any]) ?? [:]
        let name  = (meta["full_name"] as? String)
                 ?? (meta["name"] as? String)
                 ?? fallbackName
        
        return SupabaseUser(email: email, name: name)
    }
}
