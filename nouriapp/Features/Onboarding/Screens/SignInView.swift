//
//  SignInView.swift
//  nouriapp
//

import SwiftUI

struct SignInView: View {
    var onBack: () -> Void = {}
    var onAppleAuth: () -> Void = {}
    var onGoogleAuth: () -> Void = {}
    var onSignUp: () -> Void = {}

    @State private var showEmailSheet = false
    @State private var sheetDetent: PresentationDetent = .height(400)
    @EnvironmentObject var onboardingData: OnboardingData

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(NouriColors.title)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // Avatar Graphic
                    Image.bundled("sign")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(.top, 16)
                        .accessibilityLabel("Onion mascot holding Sign In sign")
                    
                    // Titles
                    Text("Welcome back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(NouriColors.title)
                        .padding(.top, 24)
                        
                    Text("Ready to scan some labels?")
                        .font(.system(size: 15))
                        .foregroundStyle(NouriColors.subtitle)
                        .padding(.top, 8)
                        
                    Spacer(minLength: 40)
                    
                    // Auth Buttons Stack
                    VStack(spacing: 12) {
                        // Apple
                        AuthButton(
                            title: "Continue with Apple",
                            textColor: .white,
                            bgColor: .black,
                            borderColor: nil,
                            action: onAppleAuth
                        ) {
                            Image(systemName: "applelogo").font(.system(size: 20))
                        }

                        // Google
                        AuthButton(
                            title: "Continue with Google",
                            textColor: NouriColors.title,
                            bgColor: .white,
                            borderColor: Color(red: 0.9, green: 0.9, blue: 0.9),
                            action: onGoogleAuth
                        ) {
                            Image.bundled("google").resizable().scaledToFit().frame(width: 20, height: 20)
                        }

                        // Divider
                        orDivider.padding(.vertical, 4)

                        // Email
                        AuthButton(
                            title: "Continue with Email",
                            textColor: NouriColors.title,
                            bgColor: Color(red: 0.96, green: 0.96, blue: 0.96),
                            borderColor: nil,
                            action: { showEmailSheet = true }
                        ) {
                            Image(systemName: "envelope").font(.system(size: 18))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 32)
                    
                    // SignUp Option Line
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundStyle(NouriColors.subtitle)
                        
                        Button(action: onSignUp) {
                            Text("Sign up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(NouriColors.brandGreen)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .background(NouriColors.canvas.ignoresSafeArea())
        .sheet(isPresented: $showEmailSheet, onDismiss: { sheetDetent = .height(400) }) {
            EmailSignInView(isFocused: { focused in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                    sheetDetent = focused ? .height(560) : .height(400)
                }
            })
            .presentationDetents([sheetDetent])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            print("🚀 [SignInView] appeared. wasOnboarded: \(onboardingData.wasOnboarded)")
        }
    }
    
    // MARK: - View Subcomponents
    
    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(NouriColors.divider)
                .frame(height: 1)
            
            Text("or")
                .font(.system(size: 14))
                .foregroundStyle(NouriColors.subtitle)
                .padding(.bottom, 2)
            
            Rectangle()
                .fill(NouriColors.divider)
                .frame(height: 1)
        }
    }
}

#Preview("Sign In View") {
    SignInView()
}
