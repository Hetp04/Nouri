//
//  TopicRegistry.swift
//  nouriapp
//

import Foundation
import SwiftUI

struct FrequencyLevel {
    let label: String
    let description: String
    let accent: Color
    let icon: String          // SF Symbol
    let value: Int            // 0 = Never … 3 = Daily
}

struct TopicItem {
    let id: String
    var icon: String? = nil
    let text: String
    var imageName: String? = nil
    var selectedImageName: String? = nil
}

struct TopicRegistry {
    static let concerns: [TopicItem] = [
        .init(id: "clean-eating", icon: "fork.knife", text: "Clean Eating"),
        .init(id: "acne-safe", icon: "drop", text: "Acne Safe"),
        .init(id: "weight-loss", icon: "figure.run", text: "Weight Loss"),
        .init(id: "kids-safe", icon: "face.smiling", text: "Kids Safe"),
        .init(id: "vegan", icon: "carrot", text: "Vegan"),
        .init(id: "high-protein", icon: "dumbbell", text: "High Protein"),
        .init(id: "low-sugar", icon: "cube", text: "Low Sugar"),
        .init(id: "heart-healthy", icon: "heart", text: "Heart Healthy"),
        .init(id: "organic", text: "Organic", imageName: "icons8-sprout", selectedImageName: "icons8-sprout 1"),
        .init(id: "non-gmo", icon: "checkmark.shield", text: "Non-GMO")
    ]
    
    static let allergies: [TopicItem] = [
        .init(id: "shellfish", icon: "fish", text: "Shellfish"),
        .init(id: "eggs", text: "Eggs", imageName: "icons8-eggs", selectedImageName: "icons8-eggs 1"),
        .init(id: "milk", text: "Milk", imageName: "icons8-milk", selectedImageName: "icons8-milk 1"),
        .init(id: "soy", text: "Soy", imageName: "soy", selectedImageName: "soyFlip"),
        .init(id: "gluten", icon: "leaf", text: "Gluten"),
        .init(id: "nuts", text: "Nuts", imageName: "icons8-nuts", selectedImageName: "icons8-hazelnut"),
        .init(id: "sesame", text: "Sesame", imageName: "icons8-seed-packet", selectedImageName: "icons8-seed-packet 1"),
        .init(id: "wheat", text: "Wheat", imageName: "icons8-wheat"),
        .init(id: "corn", text: "Corn", imageName: "icons8-corn", selectedImageName: "icons8-corn 1")
    ]
    
    static let shopping: [TopicItem] = [
        .init(id: "meat-seafood", icon: "fish", text: "Meat/Seafood"),
        .init(id: "supplements", text: "Supplements", imageName: "icons8-pill", selectedImageName: "icons8-pill 1"),
        .init(id: "snacks", icon: "popcorn", text: "Snacks"),
        .init(id: "dairy-eggs", icon: "oval", text: "Dairy/Eggs"),
        .init(id: "produce", text: "Produce", imageName: "icons8-vegetable", selectedImageName: "icons8-broccoli"),
        .init(id: "frozen", icon: "snowflake", text: "Frozen"),
        .init(id: "pantry", icon: "archivebox", text: "Pantry"),
        .init(id: "beverages", icon: "cup.and.saucer", text: "Beverages")
    ]
    
    static let frequencyLevels: [FrequencyLevel] = [
        FrequencyLevel(label: "Never",  description: "Avoid completely",        accent: Color(red: 76/255,  green: 175/255, blue: 80/255),  icon: "xmark.circle", value: 0),
        FrequencyLevel(label: "Rarely", description: "Occasionally",            accent: Color(red: 255/255, green: 193/255, blue: 7/255),   icon: "hourglass",    value: 1),
        FrequencyLevel(label: "Often",  description: "Several times a week",    accent: Color(red: 255/255, green: 152/255, blue: 0/255),   icon: "clock",        value: 2),
        FrequencyLevel(label: "Daily",  description: "Every day",               accent: Color(red: 244/255, green: 67/255,  blue: 54/255),  icon: "calendar",     value: 3),
    ]
    
    static func getConcern(id: String) -> TopicItem? {
        concerns.first { $0.id == id }
    }
    
    static func getAllergy(id: String) -> TopicItem? {
        allergies.first { $0.id == id }
    }
}
