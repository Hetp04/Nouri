import Foundation
import SwiftUI

// MARK: - Enums

enum WeightUnit: String, CaseIterable { case kg = "Kg", pound = "Pound" }
enum HeightUnit: String, CaseIterable { case cm = "Cm",  ft = "Ft" }

enum ActivityLevel: String, CaseIterable {
    case sedentary        = "Sedentary"
    case lightlyActive    = "Lightly active"
    case moderatelyActive = "Moderately active"
    case veryActive       = "Very active"
    case athlete          = "Athlete"

    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Exercise 1-3 times/week"
        case .moderatelyActive: return "Exercise 4-5 times/week"
        case .veryActive: return "Daily exercise or intense sports"
        case .athlete: return "Vary intense exercise, 2x per day"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: return "figure.hand.cycling"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.strengthtraining.traditional"
        case .athlete: return "figure.american.football"
        }
    }


    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .athlete: return 1.9
        }
    }
}

enum Sex: String, CaseIterable { case male = "Male", female = "Female" }

// MARK: - Calorie Math

enum CalorieCalculator {
    static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }
    
    static func maintenanceCalories(bmr: Double, activityLevel: ActivityLevel) -> Int {
        Int(round(bmr * activityLevel.multiplier))
    }
    
    static func maintenanceCalories(weightKg: Double, heightCm: Double, age: Int, sex: Sex, activity: ActivityLevel) -> Int {
        let baseBMR = bmr(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex)
        return maintenanceCalories(bmr: baseBMR, activityLevel: activity)
    }
}

// MARK: - Conversion Helpers

enum UnitConvert {
    static func kgToLb(_ kg: Double) -> Double {
        Measurement(value: kg, unit: UnitMass.kilograms).converted(to: .pounds).value
    }
    static func lbToKg(_ lb: Double) -> Double {
        Measurement(value: lb, unit: UnitMass.pounds).converted(to: .kilograms).value
    }
    static func cmToFt(_ cm: Double) -> Double {
        Measurement(value: cm, unit: UnitLength.centimeters).converted(to: .feet).value
    }
    static func ftToCm(_ ft: Double) -> Double {
        Measurement(value: ft, unit: UnitLength.feet).converted(to: .centimeters).value
    }
}

// MARK: - View Formatting & Physics Math

enum RulerMath {
    static let maxFlingVelocity: CGFloat = 2000
    static let frictionDecay: Double = 0.92

    static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
    static func snap(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
    static func snapKgForDisplay(_ kg: Double, isPound: Bool) -> Double {
        isPound ? UnitConvert.lbToKg(snap(UnitConvert.kgToLb(kg))) : snap(kg)
    }
    static func snapCmForDisplay(_ cm: Double, isFeet: Bool) -> Double {
        isFeet ? UnitConvert.ftToCm(snap(UnitConvert.cmToFt(cm))) : snap(cm)
    }
    static func dragKg(_ kg: Double, deltaPixels: Double, sensitivity: Double, isPound: Bool) -> Double {
        if isPound {
            let lb = UnitConvert.kgToLb(kg) - deltaPixels * sensitivity
            return UnitConvert.lbToKg(lb)
        } else {
            return kg - deltaPixels * sensitivity
        }
    }

    static func dragCm(_ cm: Double, deltaPixels: Double, pxPerCm: Double, isFeet: Bool) -> Double {
        if isFeet {
            let ftPerPixel = 1.0 / (pxPerCm * UnitConvert.ftToCm(1))
            let ft = UnitConvert.cmToFt(cm) - deltaPixels * ftPerPixel
            return UnitConvert.ftToCm(ft)
        } else {
            return cm - deltaPixels / pxPerCm
        }
    }
}
