//
//  NouriConfig.swift
//  nouriapp
//
//  Centralized configuration for API keys and URLs.
//

import Foundation

struct NouriConfig {
    static let supabaseURL = "https://ounoczqkszaxswkdrznl.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91bm9jenFrc3pheHN3a2Ryem5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjE5ODEsImV4cCI6MjA5MTU5Nzk4MX0.VkWYi2g0gRSX2vyDe9a8eUkGvzKl7NxYaFhjh5eVzWw"
    
    static let resendKey = "re_fgcTYCLV_F7WThbsM9VJWX91cR6SNRQ7d"
    static let resendFromEmail = "noreply@itsnouri.ca"
    
    // API Paths
    enum Path {
        static let authSignUp  = "/auth/v1/signup"
        static let authSignIn  = "/auth/v1/token?grant_type=password"
        static let authIdToken = "/auth/v1/token?grant_type=id_token" // Apple / Google id_token exchange
        static let authUser    = "/auth/v1/user"                      // Get authenticated user profile
        static let authLogout  = "/auth/v1/logout"
        static let restOTP     = "/rest/v1/otp_codes"
        static let restVerify  = "/rest/v1/email_verifications"
        static let restProfiles = "/rest/v1/user_profiles"
        static let restDailyNotes = "/rest/v1/daily_notes"

    }
    
    // Global App Constants
    enum Constants {
        static let isLoggedInKey = "isLoggedIn"
        static let googleRedirectURI = "nouri-app://auth/callback"
        static let resendApiURL = "https://api.resend.com/emails"
    }
}
