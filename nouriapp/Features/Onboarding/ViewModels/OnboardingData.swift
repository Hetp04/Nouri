//
//  OnboardingData.swift
//  nouriapp
//

import SwiftUI
import Combine

// MARK: - DTO

struct UserProfileDTO: Codable {
    var concerns: [String]?
    var otherConcerns: String?
    var allergies: [String]?
    var otherAllergies: String?
    var shoppingCategories: [String]?
    var otherShopping: String?
    var processLevel: Int?
    var calorieGoal: Int?
}

// MARK: - OnboardingData

class OnboardingData: ObservableObject {
    // Shared instance
    static let shared = OnboardingData()
    
    // Concerns
    @Published var concerns: Set<String> = []
    @Published var otherConcerns: String = ""
    
    // Allergies
    @Published var allergies: Set<String> = []
    @Published var otherAllergies: String = ""
    
    // Shopping
    @Published var shoppingCategories: Set<String> = []
    @Published var otherShopping: String = ""
    
    // Flag to track if the user actually went through the flow
    @Published var wasOnboarded: Bool = false
    
    // Conflict resolution
    @Published var showConflictAlert: Bool = false
    @Published var pendingEmail: String = ""
    
    // Constants
    static let defaultProcessLevel: Int = 0
    static let defaultCalorieGoal: Int = 800
    
    // ProcessLevel (0 = Never, 3 = Daily)
    @Published var processLevel: Int = OnboardingData.defaultProcessLevel
    
    // CalorieGoal
    @Published var calorieGoal: Int = OnboardingData.defaultCalorieGoal
    
    // Helper to check if the user actually picked anything
    var hasSelections: Bool {
        !concerns.isEmpty || !otherConcerns.isEmpty ||
        !allergies.isEmpty || !otherAllergies.isEmpty ||
        !shoppingCategories.isEmpty || !otherShopping.isEmpty ||
        processLevel != 0
        // We exclude calorieGoal because it always has a default value
    }
    
    // Convert to dictionary for Supabase payload
    func toDictionary() -> [String: Any] {
        let dto = UserProfileDTO(
            concerns: Array(concerns),
            otherConcerns: otherConcerns,
            allergies: Array(allergies),
            otherAllergies: otherAllergies,
            shoppingCategories: Array(shoppingCategories),
            otherShopping: otherShopping,
            processLevel: processLevel,
            calorieGoal: calorieGoal
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(dto),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
    
    // Load data from Supabase payload
    func update(from dto: UserProfileDTO) {
        self.concerns = Set(dto.concerns ?? [])
        self.otherConcerns = dto.otherConcerns ?? ""
        self.allergies = Set(dto.allergies ?? [])
        self.otherAllergies = dto.otherAllergies ?? ""
        self.shoppingCategories = Set(dto.shoppingCategories ?? [])
        self.otherShopping = dto.otherShopping ?? ""
        if let pl = dto.processLevel { self.processLevel = pl }
        if let cg = dto.calorieGoal { self.calorieGoal = cg }
        self.wasOnboarded = true
    }
}
