import SwiftUI

extension Color {
    // MARK: - Dynamic Theme Colors

    private static var settings: AppSettings { AppSettings.shared }

    private static var currentAccentHex: String {
        settings.currentTheme.accentHex
    }

    // Secondary brand color - the accent
    static var appSecondary: Color {
        Color(hex: currentAccentHex)
    }

    // Accent color
    static var appAccent: Color {
        Color(hex: currentAccentHex)
    }

    // MARK: - Semantic Colors

    // Background colors
    static var appBackground: Color {
        Color(hex: settings.currentTheme.backgroundHex)
    }

    static var appSecondaryBackground: Color {
        Color(hex: settings.currentTheme.cardBackgroundHex)
    }

    static let appTertiaryBackground = Color(UIColor.tertiarySystemBackground)

    // Text colors
    static var appText: Color {
        Color(hex: settings.currentTheme.textHex)
    }

    static let appSecondaryText = Color(UIColor.secondaryLabel)
    static let appTertiaryText = Color(UIColor.tertiaryLabel)

    // MARK: - Component-Specific Colors

    // Buttons
    static var appButtonBackground: Color { appAccent }
    static var appButtonBackgroundSelected: Color { appSecondary }
    static let appButtonBackgroundUnselected = Color(UIColor.systemGray5)
    static let appButtonText = Color.white
    static let appButtonTextUnselected = Color(UIColor.secondaryLabel)

    // Text fields
    static let appTextFieldBackground = Color(UIColor.systemBackground)
    static var appTextFieldBorder: Color { appAccent.opacity(0.5) }
    static let appTextFieldText = Color(UIColor.label)

    // Result boxes
    static let appResultBackground = Color(UIColor.secondarySystemBackground)

    // Checkmarks and interactive elements
    static var appCheckmarkActive: Color { appSecondary }
    static let appCheckmarkInactive = Color(UIColor.systemGray3)

    // Hint/Info text
    static var appHintText: Color { appSecondary }

    // Icons and accents
    static var appIconTint: Color { appSecondary }

    // Ruler background
    static let appRulerBackground = Color(UIColor.systemBackground)

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64

        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    // Convert Color to hex string
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
