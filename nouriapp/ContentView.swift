//
//  ContentView.swift
//  nouriapp
//
//  Root shell — keep navigation and top-level state here; screens live under Features/.
//

import SwiftUI

enum OnboardingScreen: Int {
    case welcome      = 0
    case concerns     = 1
    case allergies    = 2
    case shopping     = 3
    case processLevel = 4
    case facts        = 5
    case calorieGoal  = 6
    case compare      = 7
    case valueProp    = 8
    case signUp       = 9
    case signIn       = 10

    var progress: Double? {
        switch self {
        case .welcome:      return nil
        case .concerns:     return 1/5
        case .allergies:    return 2/5
        case .shopping:     return 3/5
        case .processLevel: return 4/5
        case .facts:        return 5/5
        case .calorieGoal:  return 5/5
        case .compare:      return 5/5
        case .valueProp:    return 5/5
        case .signUp:       return nil
        case .signIn:       return nil
        }
    }
}

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @StateObject private var socialAuth = SocialAuthManager.shared
    @StateObject private var onboardingData = OnboardingData.shared
    @State private var currentScreen: OnboardingScreen = .welcome
    @State private var previousScreen: OnboardingScreen = .welcome
    @State private var goingForward: Bool = true
    @State private var isValidatingSession: Bool = true
    @State private var hasValidatedSession: Bool = false

    // Transition direction is driven by goingForward
    private var transition: AnyTransition {
        goingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading),  removal: .move(edge: .trailing))
    }

    var body: some View {
        Group {
            if isValidatingSession {
                // Brief loading state while we check the token
                ZStack {
                    NouriColors.canvas.ignoresSafeArea()
                    ProgressView()
                        .tint(NouriColors.brandGreen)
                }
            } else if isLoggedIn {
                HomeView()
            } else {
                onboardingFlow
            }
        }
        .environmentObject(onboardingData)
        .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
        .onOpenURL { url in
            Task { await socialAuth.handleGoogleCallback(url: url) }
        }
        .fullScreenCover(isPresented: $socialAuth.showSocialOTP) {
            SocialOTPView()
        }
        .task {
            // THE FIX: Bypass if we are in an Xcode Preview, or if we already checked the token!
            // Hot reloads will no longer cause you to get randomly logged out.
            if hasValidatedSession || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                isValidatingSession = false
                return
            }
            
            hasValidatedSession = true
            
            // Validate session on app launch
            if isLoggedIn {
                let isValid = await socialAuth.validateSession()
                if !isValid {
                    isLoggedIn = false
                }
            }
            isValidatingSession = false
        }
    }

    private var onboardingFlow: some View {
        VStack(spacing: 0) {
            // Global progress bar
            if let progress = currentScreen.progress {
                NouriProgressBar(progress: progress)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .transition(.opacity)
            }

            // Screen host
            currentScreenView
                .id(currentScreen)             // Tells SwiftUI to re-render when screen changes
                .transition(transition)        // Applies directional slide once
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(NouriColors.canvas.ignoresSafeArea())
        }
        .environmentObject(onboardingData)
        .task {
            // Preload FactsView GIFs immediately at app launch on a low-priority
            // background thread — they'll be cached long before the user gets there
            let names = ["diabetes", "flask", "bpa-free", "dropper"]
            await withTaskGroup(of: Void.self) { group in
                for name in names {
                    group.addTask(priority: .utility) {
                        AnimatedGIFImage.preload(named: name)
                    }
                }
            }
        }
    }

    // Helper returning the active view
    @ViewBuilder
    private var currentScreenView: some View {
        switch currentScreen {
        case .welcome:
            WelcomeView(
                onGetStarted: { navigate(to: .concerns) },
                onSignIn:     { navigate(to: .signIn) }
            )
        case .concerns:
            ConcernsView(
                onBack: { navigate(to: .welcome) },
                onNext: { navigate(to: .allergies) }
            )
        case .allergies:
            AllergiesView(
                onBack: { navigate(to: .concerns) },
                onNext: { navigate(to: .shopping) }
            )
        case .shopping:
            ShoppingView(
                onBack: { navigate(to: .allergies) },
                onNext: { navigate(to: .processLevel) }
            )
        case .processLevel:
            ProcessLevelView(
                animateHint: goingForward,
                onBack: { navigate(to: .shopping) },
                onNext: { navigate(to: .facts) }
            )
        case .facts:
            FactsView(
                onBack: { navigate(to: .processLevel) },
                onNext: { navigate(to: .calorieGoal) }
            )
        case .calorieGoal:
            CalorieGoalView(
                onBack: { navigate(to: .facts) },
                onNext: { navigate(to: .compare) }
            )
        case .compare:
            CompareScreenView(
                onBack: { navigate(to: .calorieGoal) },
                onNext: { navigate(to: .valueProp) },
                startAtLastProduct: !goingForward
            )
        case .valueProp:
            ValuePropView(
                onBack: { navigate(to: .compare) },
                onNext: {
                    onboardingData.wasOnboarded = true
                    navigate(to: .signUp)
                }
            )
        case .signUp:
            SignUpView(
                onBack: { navigate(to: .valueProp) },
                onAppleAuth: { socialAuth.signInWithApple() },
                onGoogleAuth: { socialAuth.signInWithGoogle() },
                onSignIn: { navigate(to: .signIn) }
            )
        case .signIn:
            SignInView(
                onBack: { navigate(to: previousScreen) },
                onAppleAuth: { socialAuth.signInWithApple() },
                onGoogleAuth: { socialAuth.signInWithGoogle() },
                onSignUp: { navigate(to: .signUp) }
            )
        }
    }

    private func navigate(to screen: OnboardingScreen) {
        // Special case: if we are at Welcome (0) and going to SignIn (10), treat it as going forward visually
        // but if we go SignIn -> Welcome, or SignIn -> SignUp, use custom directions to make things flow nicely.
        // For simplicity, rawValue > current handles standard left/right sliding.
        let isForward = screen.rawValue > currentScreen.rawValue
        
        // Prevent storing the same screen history back-and-forth infinitely
        if screen != currentScreen {
            previousScreen = currentScreen
        }
        
        goingForward = isForward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }
}

#Preview {
    ContentView()
}

struct SocialOTPView: View {
    @StateObject private var socialAuth = SocialAuthManager.shared
    @State private var code = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            NouriColors.canvas.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button("Cancel") {
                        socialAuth.showSocialOTP = false
                        socialAuth.pendingSocialUser = nil
                        socialAuth.errorMessage = ""
                    }
                    .foregroundStyle(NouriColors.brandGreen)
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 6) {
                    Text("Verify Email")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(NouriColors.title)
                    Text("We sent a code to\n\(socialAuth.pendingSocialUser?.email ?? "your email")")
                        .font(.system(size: 14))
                        .foregroundStyle(NouriColors.subtitle)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                OTPInputView(code: $code)
                
                if !socialAuth.errorMessage.isEmpty {
                    Text(socialAuth.errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
                
                // Resend button with cooldown
                Button(action: {
                    Task { await socialAuth.resendSocialOTP() }
                }) {
                    if socialAuth.canResendSocialOTP {
                        Text("Resend Code")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NouriColors.brandGreen)
                    } else {
                        Text("Resend in \(socialAuth.socialOTPResendSecs)s")
                            .font(.system(size: 14))
                            .foregroundStyle(NouriColors.subtitle)
                    }
                }
                .disabled(!socialAuth.canResendSocialOTP)

                Spacer()
                
                ActionButton(title: "Verify & Continue", isLoading: socialAuth.isLoading) {
                    await socialAuth.verifySocialOTP(code: code)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}


