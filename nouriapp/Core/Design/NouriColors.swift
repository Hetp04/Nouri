//
//  NouriColors.swift
//  nouriapp
//

import SwiftUI

enum NouriColors {
    /// Splash / welcome background (`#FFFEFB`)
    static let canvas = Color(red: 1, green: 254 / 255, blue: 251 / 255)

    /// Primary headings (`#111111`)
    static let title = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)

    /// Body copy — `rgba(60, 60, 67, 0.72)`
    static let subtitle = Color(red: 60 / 255, green: 60 / 255, blue: 67 / 255).opacity(0.72)

    /// Brand green — buttons + highlight (`#2F6B4F`)
    static let brandGreen = Color(red: 47 / 255, green: 107 / 255, blue: 79 / 255)

    /// Secondary button label — a touch stronger than RN default so it reads on `#FFFEFB`
    static let secondaryLabel = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255).opacity(0.88)

    /// Secondary outline — still flat; slightly darker than `0.1` so the pill doesn’t disappear on the canvas
    static let secondaryStroke = Color.black.opacity(0.2)

    static let primaryButtonLabel = Color.white

    // MARK: - Onboarding / Concerns Specific Colors

    static let chipText = Color(red: 53/255, green: 55/255, blue: 64/255)       // #353740
    static let chipBorder = Color(red: 229/255, green: 229/255, blue: 229/255)  // #E5E5E5
    static let chipIcon = Color(red: 110/255, green: 110/255, blue: 128/255)    // #6E6E80
    
    static let inputPlaceholder = Color(red: 161/255, green: 161/255, blue: 170/255) // #A1A1AA
    static let divider = Color(red: 236/255, green: 236/255, blue: 241/255)     // #ECECF1
    
    static let disabledButton = Color(red: 217/255, green: 217/255, blue: 227/255) // #D9D9E3
    static let backButtonBg = Color(red: 243/255, green: 244/255, blue: 246/255) // #F3F4F6
    static let progressLine = Color(red: 229/255, green: 231/255, blue: 235/255) // #E5E7EB
    
    // MARK: - Tips / Guidance
    static let tipIcon = Color(red: 245/255, green: 158/255, blue: 11/255)       // #F59E0B (Amber)
    static let tipBackground = Color(red: 255/255, green: 251/255, blue: 235/255) // #FFFBEB (Very light Amber)
    
    // MARK: - Product Feedback
    static let badProductRed = Color(red: 192/255, green: 57/255, blue: 43/255) // #C0392B
    
    // MARK: - Home / Dashboard
    static let iconBgColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    static let sparkleBgColor = Color(red: 255/255, green: 240/255, blue: 230/255)
    static let sparkleColor = Color(red: 160/255, green: 110/255, blue: 90/255)
}
