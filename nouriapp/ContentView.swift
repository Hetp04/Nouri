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
    @State private var currentScreen: OnboardingScreen = .welcome
    @State private var previousScreen: OnboardingScreen = .welcome
    @State private var goingForward: Bool = true

    // Transition direction is driven by goingForward
    private var transition: AnyTransition {
        goingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading),  removal: .move(edge: .trailing))
    }

    var body: some View {
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
                onNext: { navigate(to: .signUp) }
            )
        case .signUp:
            SignUpView(
                onBack: { navigate(to: .valueProp) },
                onAppleAuth: { print("Apple Auth") },
                onGoogleAuth: { print("Google Auth") },
                onSignIn: { navigate(to: .signIn) }
            )
        case .signIn:
            SignInView(
                onBack: { navigate(to: previousScreen) },
                onAppleAuth: { print("Apple Auth") },
                onGoogleAuth: { print("Google Auth") },
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

