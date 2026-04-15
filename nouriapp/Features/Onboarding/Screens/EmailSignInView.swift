//
//  EmailSignInView.swift
//  nouriapp
//

import SwiftUI

struct EmailSignInView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EmailSignInViewModel()
    
    // Callback to UI to expand/shrink sheet
    var isFocused: (Bool) -> Void = { _ in } 

    @FocusState private var fieldFocus: String?

    var body: some View {
        ZStack {
            NouriColors.canvas.ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch viewModel.phase {
                case .form:      formBody
                case .success:   successBody
                }
            }
            .padding(.horizontal, 24)
            .onChange(of: fieldFocus) { _, newValue in
                isFocused(newValue != nil)
            }
        }
    }

    // MARK: - Form Phase
    private var formBody: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                formField(label: "Email", placeholder: "Enter your email", text: $viewModel.email, icon: "envelope", id: "email", keyboardType: .emailAddress)
                formField(label: "Password", placeholder: "Enter your password", text: $viewModel.password, icon: "lock", id: "password", isSecure: true)
            }
            .padding(.top, 32)
            
            HStack {
                Spacer()
                Button("Forgot password?") {
                    // TODO: Reset password flow
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(NouriColors.brandGreen)
            }
            .padding(.vertical, 8)

            msgArea
            Spacer()
            
            ActionButton(title: "Sign In", isLoading: viewModel.isLoading) {
                await viewModel.handleSignIn(onPhaseChange: { isFocused(false) })
            }
            .padding(.bottom, 20)
        }
    }

    private func formField(label: String, placeholder: String, text: Binding<String>, icon: String, id: String, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
        return FormField(
            label: label,
            placeholder: placeholder,
            text: text,
            icon: icon,
            isFocused: fieldFocus == id,
            isSecure: isSecure,
            keyboardType: keyboardType,
            strengthColor: nil,
            strengthWidth: nil,
            onTap: {
                fieldFocus = id
            }
        )
        .focused($fieldFocus, equals: id)
    }

    // MARK: - Success Phase
    private var successBody: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(NouriColors.brandGreen)
            Text("Welcome back!").font(.system(size: 24, weight: .bold)).foregroundStyle(NouriColors.title)
            Text("Signing you in...").font(.system(size: 15)).foregroundStyle(NouriColors.subtitle)
            Spacer()
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() } }
    }

    private var msgArea: some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage).font(.system(size: 13)).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
    }
}
