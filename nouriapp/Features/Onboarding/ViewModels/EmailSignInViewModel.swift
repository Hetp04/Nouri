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
        
        do {
            try await auth.signIn(email: email, password: password)
            phase = .success
            onPhaseChange()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
