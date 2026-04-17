//
//  KeychainManager.swift
//  nouriapp
//
//  Secure storage for session data using the iOS Keychain.
//  UserDefaults is plain text; Keychain is encrypted and sandboxed.
//

import Foundation
import Security

enum KeychainManager {
    
    private static let service = "com.nouri.app"
    
    // Keys
    static let accessTokenKey = "supabase_access_token"
    static let refreshTokenKey = "supabase_refresh_token"
    static let userEmailKey = "user_email"
    static let userNameKey = "user_name"
    
    // MARK: - Save
    
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing item first to avoid duplicates
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
            kSecValueData as String:    data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Read
    
    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All Session Data
    
    static func clearSession() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
        delete(key: userEmailKey)
        delete(key: userNameKey)
    }
    
    // MARK: - Convenience: Save Full Session
    
    static func saveSession(email: String, name: String, accessToken: String = "", refreshToken: String = "") {
        save(key: userEmailKey, value: email)
        save(key: userNameKey, value: name)
        if !accessToken.isEmpty { save(key: accessTokenKey, value: accessToken) }
        if !refreshToken.isEmpty { save(key: refreshTokenKey, value: refreshToken) }
    }
}
