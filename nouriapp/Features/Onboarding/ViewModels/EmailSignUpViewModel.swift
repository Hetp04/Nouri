//
//  EmailSignUpViewModel.swift
//  nouriapp
//

import SwiftUI
import Combine

enum SignUpPhase { case form, verifying, success }

@MainActor
class EmailSignUpViewModel: ObservableObject {
    // Inputs
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var otpCode = ""
    
    // UI State
    @Published var phase: SignUpPhase = .form
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var resendSecs = 30
    @Published var canResend = false
    
    // Password Strength (0.0 to 1.0)
    var passwordStrength: Double {
        if password.isEmpty { return 0 }
        var score: Double = 0
        if password.count >= 6 { score += 0.3 }
        if password.count >= 8 { score += 0.2 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 0.25 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")) != nil { score += 0.25 }
        return score
    }
    
    var strengthColor: Color {
        if passwordStrength < 0.4 { return .red.opacity(0.8) }
        if passwordStrength < 0.7 { return .orange }
        return Color(red: 0x48/255, green: 0x93/255, blue: 0x6E/255) // Nouri Green
    }
    
    private var timerTask: Task<Void, Never>?
    
    // Dependencies
    private let auth = NouriAuth.shared
    
    // MARK: - Actions
    
    func handleSignUp(onPhaseChange: @escaping () -> Void) async {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = ""
        email = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        do {
            try await auth.signUp(email: email, password: password, name: fullName)
            phase = .verifying
            onPhaseChange()
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func handleVerify() async {
        guard otpCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await auth.verifyOTP(email: email, code: otpCode)
            timerTask?.cancel()
            // Tie onboarding data to account securely
            SocialAuthManager.shared.persistSession(email: email, name: fullName)
            await auth.syncProfile(email: email)
            phase = .success
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func handleResend() async {
        errorMessage = ""
        do {
            try await auth.resendOTP(email: email)
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helpers
    
    private func validateForm() -> Bool {
        if fullName.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."; return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."; return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."; return false
        }
        return true
        
    }
    
    private func startTimer() {
        timerTask?.cancel()
        resendSecs = 30
        canResend = false

        
        timerTask = Task {
            for i in stride(from: 30, through: 1, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                resendSecs = i - 1
            }
            canResend = true
        }
    }
    
    deinit {
        timerTask?.cancel()
    }
}
