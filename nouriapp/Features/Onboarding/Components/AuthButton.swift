//
//  AuthButton.swift
//  nouriapp
//

import SwiftUI

struct AuthButton<Icon: View>: View {
    let title: String
    let textColor: Color
    let bgColor: Color
    let borderColor: Color?
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                icon()
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(AuthButtonStyle(bgColor: bgColor, textColor: textColor, borderColor: borderColor))
    }
}

struct AuthButtonStyle: ButtonStyle {
    let bgColor: Color
    let textColor: Color
    let borderColor: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(bgColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        Capsule().stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
