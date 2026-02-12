//
//  CustomThemeView.swift
//  KnitAndCalc
//
//  Editor for custom color theme with live preview
//

import SwiftUI

struct CustomThemeView: View {
    @ObservedObject var settings = AppSettings.shared

    @State private var accentColor: Color
    @State private var backgroundColor: Color
    @State private var cardColor: Color
    @State private var textColor: Color

    init() {
        let s = AppSettings.shared
        _accentColor = State(initialValue: Color(hex: s.customAccentHex))
        _backgroundColor = State(initialValue: Color(hex: s.customBackgroundHex))
        _cardColor = State(initialValue: Color(hex: s.customCardBackgroundHex))
        _textColor = State(initialValue: Color(hex: s.customTextHex))
    }

    var body: some View {
        Form {
            // Live preview
            Section(header: Text("Forhåndsvisning")) {
                VStack(spacing: 0) {
                    // Simulated list rows
                    previewRow(icon: "🧵", title: "Prosjekter")
                    Divider()
                    previewRow(icon: "🧶", title: "Garnlager")
                    Divider()
                    previewRow(icon: "📝", title: "Oppskrifter")
                }
                .background(cardColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 4)
            }
            .listRowBackground(backgroundColor)

            Section(header: Text("Piler / ikonfarge")) {
                ColorPicker("Piler", selection: $accentColor, supportsOpacity: false)
                    .onChange(of: accentColor) { newValue in
                        settings.customAccentHex = newValue.hexString
                    }
            }

            Section(header: Text("Bakgrunn")) {
                ColorPicker("Hovedbakgrunn", selection: $backgroundColor, supportsOpacity: false)
                    .onChange(of: backgroundColor) { newValue in
                        settings.customBackgroundHex = newValue.hexString
                    }
                ColorPicker("Kort/seksjon", selection: $cardColor, supportsOpacity: false)
                    .onChange(of: cardColor) { newValue in
                        settings.customCardBackgroundHex = newValue.hexString
                    }
            }

            Section(header: Text("Tekst")) {
                ColorPicker("Tekstfarge", selection: $textColor, supportsOpacity: false)
                    .onChange(of: textColor) { newValue in
                        settings.customTextHex = newValue.hexString
                    }
            }

            Section {
                Button("Tilbakestill til standard") {
                    accentColor = Color(hex: "6b52a3")
                    backgroundColor = Color(hex: "FFFFFF")
                    cardColor = Color(hex: "f4ecff")
                    textColor = Color(hex: "000000")
                    settings.customAccentHex = "6b52a3"
                    settings.customBackgroundHex = "FFFFFF"
                    settings.customCardBackgroundHex = "f4ecff"
                    settings.customTextHex = "000000"
                }
                .foregroundColor(.red)
            }
        }
        .themedForm()
        .navigationTitle("Egendefinert tema")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settings.currentTheme = .custom
        }
    }

    private func previewRow(icon: String, title: String) -> some View {
        HStack {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 36)
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(textColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
