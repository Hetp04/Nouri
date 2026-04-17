//
//  EmailSignUpView.swift
//  nouriapp
//

import SwiftUI

struct EmailSignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EmailSignUpViewModel()
    
    // Callback to UI to expand/shrink sheet
    var isFocused: (Bool) -> Void = { _ in } 

    @FocusState private var fieldFocus: String?

    var body: some View {
        ZStack {
            NouriColors.canvas.ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch viewModel.phase {
                case .form:      formBody
                case .verifying: otpBody
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
                formField(label: "Full Name", placeholder: "Enter your name", text: $viewModel.fullName, icon: "person", id: "name")
                formField(label: "Email", placeholder: "Enter your email", text: $viewModel.email, icon: "envelope", id: "email", keyboardType: .emailAddress)
                formField(label: "Password", placeholder: "Enter your password", text: $viewModel.password, icon: "lock", id: "password", isSecure: true)
                formField(label: "Confirm Password", placeholder: "Confirm your password", text: $viewModel.confirmPassword, icon: "lock", id: "confirm", isSecure: true)
            }
            .padding(.top, 32)

            msgArea
            Spacer()
            
            ActionButton(title: "Create Account", isLoading: viewModel.isLoading) {
                await viewModel.handleSignUp(onPhaseChange: { isFocused(false) })
            }
            .padding(.bottom, 20)
        }
    }

    private func formField(label: String, placeholder: String, text: Binding<String>, icon: String, id: String, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
        let isPasswordField = id == "password"
        
        return FormField(
            label: label,
            placeholder: placeholder,
            text: text,
            icon: icon,
            isFocused: fieldFocus == id,
            isSecure: isSecure,
            keyboardType: keyboardType,
            strengthColor: isPasswordField ? viewModel.strengthColor : nil,
            strengthWidth: isPasswordField ? viewModel.passwordStrength : nil,
            onTap: {
                fieldFocus = id
            }
        )
        .focused($fieldFocus, equals: id)
    }

    // MARK: - OTP Phase
    private var otpBody: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Check your email").font(.system(size: 22, weight: .bold)).foregroundStyle(NouriColors.title)
                Text("We sent a 6-digit code to\n\(viewModel.email)").font(.system(size: 14)).foregroundStyle(NouriColors.subtitle).multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            OTPInputView(code: $viewModel.otpCode)
            
            msgArea

            Button(action: { Task { await viewModel.handleResend() } }) {
                Text(viewModel.canResend ? "Resend code" : "Resend in \(viewModel.resendSecs)s")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.canResend ? NouriColors.brandGreen : NouriColors.subtitle)
            }
            .disabled(!viewModel.canResend)

            Spacer()
            ActionButton(title: "Verify Email", isLoading: viewModel.isLoading) { await viewModel.handleVerify() }
                .padding(.bottom, 20)
        }
    }

    // MARK: - Success Phase
    private var successBody: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(NouriColors.brandGreen)
            Text("You're all set!").font(.system(size: 24, weight: .bold)).foregroundStyle(NouriColors.title)
            Text("Your account has been created.").font(.system(size: 15)).foregroundStyle(NouriColors.subtitle)
            Spacer()
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() } }
    }

    private var msgArea: some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage).font(.system(size: 13)).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Components

struct ActionButton: View {
    let title: String
    let isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button(action: { Task { await action() } }) {
            ZStack {
                if isLoading { ProgressView().tint(.white) }
                else { Text(title).font(.system(size: 16, weight: .bold)) }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(NouriColors.brandGreen, in: Capsule())
        }
        .disabled(isLoading)
    }
}

struct OTPInputView: View {
    @Binding var code: String
    @FocusState private var isFocusedField: Bool
    
    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocusedField)
                .onChange(of: code) { _, v in if v.count > 6 { code = String(v.prefix(6)) } }
                .opacity(0).frame(width: 1, height: 1)
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { i in
                    let digit = i < code.count ? String(code[code.index(code.startIndex, offsetBy: i)]) : ""
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.04))
                        .frame(width: 44, height: 54)
                        .overlay(Text(digit).font(.system(size: 20, weight: .bold)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(digit.isEmpty ? Color.clear : NouriColors.brandGreen, lineWidth: 2))
                }
            }
        }
        .onAppear { isFocusedField = true }
        .onTapGesture { isFocusedField = true }
    }
}

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isFocused: Bool
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var strengthColor: Color? = nil
    var strengthWidth: Double? = nil
    var onTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(NouriColors.subtitle)
                .padding(.leading, 12)
                .frame(height: 16)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isFocused ? (strengthColor ?? NouriColors.brandGreen) : .black.opacity(0.3))
                    .font(.system(size: 18))
                    .frame(width: 24)

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .font(.system(size: 16))
                    } else {
                        TextField(placeholder, text: $text)
                            .font(.system(size: 16))
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.black.opacity(0.04), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isFocused ? (strengthColor ?? NouriColors.brandGreen) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(Capsule())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        onTap()
                    }
            )
        }
    }
}
