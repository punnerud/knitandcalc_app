import SwiftUI

extension Color {
    // MARK: - App Color Palette
    // Based on: #330000, #73605B, #D09683

    // Primary brand color - deep burgundy
    static let appPrimary = Color(hex: "330000")

    // Secondary brand color - warm taupe
    static let appSecondary = Color(hex: "73605B")

    // Accent color - soft peach
    static let appAccent = Color(hex: "D09683")

    // MARK: - Semantic Colors (Dark Mode Compatible)

    // Background colors
    static let appBackground = Color(UIColor.systemBackground)
    static let appSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let appTertiaryBackground = Color(UIColor.tertiarySystemBackground)

    // Text colors
    static let appText = Color(UIColor.label)
    static let appSecondaryText = Color(UIColor.secondaryLabel)
    static let appTertiaryText = Color(UIColor.tertiaryLabel)

    // MARK: - Component-Specific Colors

    // Buttons
    static let appButtonBackground = Color.appAccent
    static let appButtonBackgroundSelected = Color.appSecondary
    static let appButtonBackgroundUnselected = Color(UIColor.systemGray5)
    static let appButtonText = Color.white
    static let appButtonTextUnselected = Color(UIColor.secondaryLabel)

    // Text fields
    static let appTextFieldBackground = Color(UIColor.systemBackground)
    static let appTextFieldBorder = Color.appAccent.opacity(0.5)
    static let appTextFieldText = Color.appText

    // Result boxes
    static let appResultBackground = Color(UIColor.secondarySystemBackground)

    // Checkmarks and interactive elements
    static let appCheckmarkActive = Color.appSecondary
    static let appCheckmarkInactive = Color(UIColor.systemGray3)

    // Hint/Info text
    static let appHintText = Color.appSecondary

    // Icons and accents
    static let appIconTint = Color.appSecondary

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
}
