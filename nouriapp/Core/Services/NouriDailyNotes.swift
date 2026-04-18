//
//  NouriDailyNotes.swift
//  nouriapp
//
//  Production-level note persistence layer.
//
//  Pattern (similar to Notion/Google Docs for single-user):
//    • Local-first: reads come from in-memory cache instantly after first load
//    • Dirty tracking: only hits the network when text actually changed
//    • Debounced upsert: no network calls during active typing
//    • Proper PostgREST upsert: INSERT ... ON CONFLICT DO UPDATE via Prefer header
//

import Foundation

actor NouriDailyNotes {
    static let shared = NouriDailyNotes()
    private init() {}

    // MARK: - In-Memory Cache (local-first reads)

    // Keyed by "YYYY-MM-DD". Avoids re-fetching when user swipes back to a past day.
    private var cache: [String: String] = [:]

    // Tracks what the user has typed locally but not yet confirmed on server.
    // Separate from `cache` (which is last confirmed server state).
    private var pendingWrites: [String: (email: String, content: String)] = [:]

    // MARK: - Public API

    /// Returns the note for a given date.
    /// - First call: fetches from Supabase and caches locally.
    /// - Subsequent calls: returns cached value immediately (no network).
    func fetch(email: String, date: Date) async -> String {
        let key = Self.key(for: date)
        if let cached = cache[key] {
            print("⚡️ [DailyNotes] Cache hit for \(key)")
            return cached
        }
        return await fetchFromServer(email: email, key: key)
    }

    /// Save only if content has changed from what's currently on the server.
    func saveIfDirty(email: String, date: Date, content: String) async {
        let key = Self.key(for: date)
        // Track pending write so flushAll can find it on backgrounding
        pendingWrites[key] = (email: email, content: content)
        guard cache[key] != content else {
            print("✨ [DailyNotes] Skipping save — content unchanged for \(key)")
            return
        }
        await persistToServer(email: email, key: key, content: content)
        pendingWrites.removeValue(forKey: key)
    }

    /// Immediately flush any pending writes not yet confirmed by server.
    /// Called when app enters background so in-flight debounce saves aren't lost.
    func flushAll(email: String) async {
        guard !pendingWrites.isEmpty else { return }
        print("🚿 [DailyNotes] Background flush — \(pendingWrites.count) pending write(s)...")
        for (key, pending) in pendingWrites {
            guard cache[key] != pending.content else { continue }
            await persistToServer(email: pending.email, key: key, content: pending.content)
        }
        pendingWrites.removeAll()
    }

    // MARK: - Helpers

    static func key(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    // MARK: - Private Networking

    private func fetchFromServer(email: String, key: String) async -> String {
        let path = "\(NouriConfig.Path.restDailyNotes)?user_email=eq.\(email)&date=eq.\(key)&select=content"
        print("🌐 [DailyNotes] Fetching \(key) from server...")
        do {
            let data = try await request(path: path, method: "GET")
            let rows = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
            let content = rows?.first?["content"] as? String ?? ""
            cache[key] = content
            print("✅ [DailyNotes] Fetched \(key). Length: \(content.count)")
            return content
        } catch {
            print("❌ [DailyNotes] Fetch failed for \(key): \(error)")
            return ""
        }
    }

    private func persistToServer(email: String, key: String, content: String) async {
        print("💾 [DailyNotes] Persisting \(key) to server (chars: \(content.count))...")
        let body: [String: Any] = [
            "user_email": email,
            "date": key,
            "content": content,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        do {
            try await request(
                path: "\(NouriConfig.Path.restDailyNotes)?on_conflict=user_email,date",
                method: "POST",
                body: body,
                headers: [
                    "Prefer": "resolution=merge-duplicates,return=minimal"
                ]
            )
            // Only update cache after confirmed server write
            cache[key] = content
            print("✅ [DailyNotes] Persisted \(key)")
        } catch {
            print("❌ [DailyNotes] Persist failed for \(key): \(error)")
        }
    }


    @discardableResult
    private func request(
        path: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        headers: [String: String] = [:]
    ) async throws -> Data {
        let fullURL = (path.hasPrefix("http") ? "" : NouriConfig.supabaseURL) + path
        guard let url = URL(string: fullURL) else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(NouriConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let token = KeychainManager.read(key: KeychainManager.accessTokenKey) ?? NouriConfig.supabaseAnonKey
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, res) = try await URLSession.shared.data(for: req)
        if let http = res as? HTTPURLResponse {
            print("📡 [DailyNotes] \(method) \(http.statusCode) \(path.prefix(60))...")
            if http.statusCode >= 400 {
                let errorBody = String(data: data, encoding: .utf8) ?? "no body"
                print("❌ [DailyNotes] Error body: \(errorBody)")
                throw URLError(.badServerResponse)
            }
        }
        return data
    }
}
