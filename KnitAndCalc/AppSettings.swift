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

enum AppTheme: String, CaseIterable {
    case standard = "standard"
    case ocean = "ocean"
    case forest = "forest"
    case sunset = "sunset"
    case raspberry = "raspberry"
    case sky = "sky"
    case sand = "sand"
    case midnight = "midnight"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .ocean: return "Havblå"
        case .forest: return "Skoggrønn"
        case .sunset: return "Solnedgang"
        case .raspberry: return "Bringebær"
        case .sky: return "Himmelblå"
        case .sand: return "Varm sand"
        case .midnight: return "Nattblå"
        case .custom: return "Egendefinert"
        }
    }

    var accentHex: String {
        switch self {
        case .standard: return "6b52a3"
        case .ocean: return "2E86AB"
        case .forest: return "2E7D32"
        case .sunset: return "E65100"
        case .raspberry: return "AD1457"
        case .sky: return "0277BD"
        case .sand: return "795548"
        case .midnight: return "1A237E"
        case .custom: return AppSettings.shared.customAccentHex
        }
    }

    var backgroundHex: String {
        switch self {
        case .standard: return "f4ecff"
        case .ocean: return "e8f4f8"
        case .forest: return "e8f5e9"
        case .sunset: return "fff3e0"
        case .raspberry: return "fce4ec"
        case .sky: return "e1f5fe"
        case .sand: return "efebe9"
        case .midnight: return "e8eaf6"
        case .custom: return AppSettings.shared.customBackgroundHex
        }
    }

    var textHex: String {
        switch self {
        case .standard: return "2D1F54"
        case .ocean: return "1B3A4B"
        case .forest: return "1B4D1F"
        case .sunset: return "4E2600"
        case .raspberry: return "4A0A2A"
        case .sky: return "0A3050"
        case .sand: return "3E2C23"
        case .midnight: return "0D1242"
        case .custom: return AppSettings.shared.customTextHex
        }
    }

    var cardBackgroundHex: String {
        switch self {
        case .standard: return "FAF6FF"
        case .ocean: return "F3FAFB"
        case .forest: return "F3FAF4"
        case .sunset: return "FFF9F2"
        case .raspberry: return "FEF2F5"
        case .sky: return "F0FAFF"
        case .sand: return "F7F5F4"
        case .midnight: return "F2F3FA"
        case .custom: return AppSettings.shared.customCardBackgroundHex
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("appLanguage") var language: String = ""
    @AppStorage("unitSystem") var unitSystem: String = ""
    @AppStorage("hasSetDefaults") private var hasSetDefaults: Bool = false

    // Theme properties use @Published so objectWillChange fires and all views update
    @Published var theme: String {
        didSet { UserDefaults.standard.set(theme, forKey: "appTheme") }
    }
    @Published var customAccentHex: String {
        didSet { UserDefaults.standard.set(customAccentHex, forKey: "customAccentColor") }
    }
    @Published var customCardBackgroundHex: String {
        didSet { UserDefaults.standard.set(customCardBackgroundHex, forKey: "customCardBackground") }
    }
    @Published var customTextHex: String {
        didSet { UserDefaults.standard.set(customTextHex, forKey: "customTextColor") }
    }
    @Published var customBackgroundHex: String {
        didSet { UserDefaults.standard.set(customBackgroundHex, forKey: "customBackgroundColor") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.theme = defaults.string(forKey: "appTheme") ?? AppTheme.standard.rawValue
        self.customAccentHex = defaults.string(forKey: "customAccentColor") ?? "6b52a3"
        self.customCardBackgroundHex = defaults.string(forKey: "customCardBackground") ?? "f4ecff"
        self.customTextHex = defaults.string(forKey: "customTextColor") ?? "000000"
        self.customBackgroundHex = defaults.string(forKey: "customBackgroundColor") ?? "FFFFFF"

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

    var currentTheme: AppTheme {
        get { AppTheme(rawValue: theme) ?? .standard }
        set { theme = newValue.rawValue }
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