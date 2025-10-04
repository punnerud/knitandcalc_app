//
//  AppSettings.swift
//  KnitAndCalc
//
//  App settings and preferences
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case norwegian = "nb"
    case english = "en"
    case danish = "da"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case swedish = "sv"

    var displayName: String {
        switch self {
        case .norwegian: return "Norsk"
        case .english: return "English"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .swedish: return "Svenska"
        }
    }
}

enum UnitSystem: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"

    var displayName: String {
        switch self {
        case .metric: return NSLocalizedString("settings.unit.metric", comment: "")
        case .imperial: return NSLocalizedString("settings.unit.imperial", comment: "")
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("appLanguage") var language: String = ""
    @AppStorage("unitSystem") var unitSystem: String = ""
    @AppStorage("hasSetDefaults") private var hasSetDefaults: Bool = false

    init() {
        if !hasSetDefaults {
            setDefaultsFromLocale()
            hasSetDefaults = true
        }
    }

    var currentLanguage: AppLanguage {
        get { AppLanguage(rawValue: language) ?? .norwegian }
        set { language = newValue.rawValue }
    }

    var currentUnitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystem) ?? .metric }
        set { unitSystem = newValue.rawValue }
    }

    func setLanguage(_ lang: AppLanguage) {
        currentLanguage = lang
        UserDefaults.standard.set([lang.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    private func setDefaultsFromLocale() {
        // Set language based on system locale (iOS 15 compatible)
        let systemLanguageCode = Locale.current.languageCode ?? "en"

        switch systemLanguageCode {
        case "nb", "no":
            language = "nb"
        case "en":
            language = "en"
        case "da":
            language = "da"
        case "fi":
            language = "fi"
        case "fr":
            language = "fr"
        case "de":
            language = "de"
        case "sv":
            language = "sv"
        default:
            language = "en" // Default to English for unsupported languages
        }

        // Set unit system based on locale (iOS 15 compatible)
        let usesMetric = Locale.current.usesMetricSystem
        unitSystem = usesMetric ? "metric" : "imperial"
    }
}

// MARK: - Unit Conversion
struct UnitConverter {
    // Conversion constants
    static let metersToYards: Double = 1.09361
    static let gramsToOunces: Double = 0.035274

    // Length conversions
    static func metersToYards(_ meters: Double) -> Double {
        return meters * metersToYards
    }

    static func yardsToMeters(_ yards: Double) -> Double {
        return yards / metersToYards
    }

    // Weight conversions
    static func gramsToOunces(_ grams: Double) -> Double {
        return grams * gramsToOunces
    }

    static func ouncesToGrams(_ ounces: Double) -> Double {
        return ounces / gramsToOunces
    }

    // Format for display
    static func formatLength(_ meters: Double, unit: UnitSystem) -> String {
        switch unit {
        case .metric:
            return String(format: "%.0f m", meters)
        case .imperial:
            return String(format: "%.0f yd", metersToYards(meters))
        }
    }

    static func formatWeight(_ grams: Double, unit: UnitSystem) -> String {
        switch unit {
        case .metric:
            return String(format: "%.0f g", grams)
        case .imperial:
            return String(format: "%.1f oz", gramsToOunces(grams))
        }
    }
}