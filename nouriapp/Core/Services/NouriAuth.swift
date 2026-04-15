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

actor NouriAuth {
    static let shared = NouriAuth()
    private init() {}

    private var pending: [String: (password: String, name: String)] = [[:] as! [String: (password: String, name: String)]].first! // Simplified initialization for a dictionary

    // Note: Re-initializing for clarity
    private var users: [String: (password: String, name: String)] = [:]

    // MARK: - Public API

    func signIn(email: String, password: String) async throws {
        let e = normalize(email)
        try await request(path: NouriConfig.Path.authSignIn, body: ["email": e, "password": password])
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
        
        try await upsert(table: "otp_codes", body: ["email": e, "code": code, "expires_at": expires])
        try await sendEmail(to: e, code: code, name: name)
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
        let html = "<h2>Verify your email</h2><p>Hi \(name.isEmpty ? "there" : name),</p><p>Your code is: <b>\(code)</b></p>"
        let body = ["from": NouriConfig.resendFromEmail, "to": email, "subject": "Verify your email – Nouri", "html": html]
        let url = "https://api.resend.com/emails"
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(NouriConfig.resendKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: req)
    }

    private func normalize(_ email: String) -> String { email.lowercased().trimmingCharacters(in: .whitespaces) }
}
