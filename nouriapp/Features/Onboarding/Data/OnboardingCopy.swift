//
//  OnboardingCopy.swift
//  nouriapp
//
//  Centralized copy/strings for the onboarding flow.
//

import Foundation

struct OnboardingCopy {
    struct Concerns {
        static let title = "What do you care about?"
        static let subtitle = "Select the topics that matter most to you"
        static let accessibilityLabel = "Onion reading a book"
        static let customInputTitle = "Anything else? (optional)"
        static let customInputPlaceholder = "e.g. Kosher"
    }
    
    struct Allergies {
        static let title = "Any allergies?"
        static let subtitle = "We'll filter recipes to ensure they're safe for you."
        static let accessibilityLabel = "Onion with allergy"
        static let customInputTitle = "Anything else? (optional)"
        static let customInputPlaceholder = "e.g. Mustard"
        static let disclaimerText = "Nouri provides guidance based on ingredients, but please always verify labels for severe allergies."
    }
    
    struct Shopping {
        static let title = "What do you shop for the most?"
        static let subtitle = "Select the categories you buy most often."
        static let accessibilityLabel = "Shopping cart illustration"
        static let customInputTitle = "Anything else? (optional)"
        static let customInputPlaceholder = "e.g. Kosher options"
    }
    
    struct ProcessLevel {
        static let title = "Ultra-processed food intake"
        static let subtitle = "Select the frequency that matches your lifestyle"
        static let accessibilityLabel = "Ultra-processed food illustration"
    }
    
    struct CalorieGoal {
        static let title = "Daily calorie goal"
        static let subtitle = "Set your daily calorie target based on\nyour personal health and fitness goals."
        static let noIdeaButton = "I don't know my calories"
    }
    
    struct Facts {
        static let title = "Interesting Facts"
        static let subtitle = "Insights based on your profile to help you navigate your journey."
        static let accessibilityLabel = "Interesting facts avatar"
        static let sugarTitle = "Sugar has 60+ names"
        static let sugarContent = "Ingredients like dextrose and maltose are hidden sugars causing glucose spikes."
        static let naturalTitle = "\"Natural\" is vague"
        static let naturalContent = "\"Natural flavors\" can contain 100+ synthetic chemicals and compounds."
        static let labelsTitle = "Labels can mislead"
        static let labelsContent = "\"Low fat\" often means added sugar to replace the lost flavor."
        static let dyeTitle = "Red Dye #40"
        static let dyeContent = "Made from petroleum and banned in parts of Europe with other colors."
    }
    
    struct ValueProp {
        static let tag = "Product Comparison"
        static let title = "So stop guessing,\nstart knowing"
        static let subtitle = "Nouri decodes every label in seconds."
    }
}
