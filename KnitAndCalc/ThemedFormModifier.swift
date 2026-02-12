//
//  ThemedFormModifier.swift
//  KnitAndCalc
//
//  Applies theme colors to Form/List backgrounds
//

import SwiftUI

struct ThemedFormModifier: ViewModifier {
    @ObservedObject private var settings = AppSettings.shared

    func body(content: Content) -> some View {
        // UIKit appearance for cell backgrounds (preserves separators)
        let _ = updateCellAppearance()

        if #available(iOS 16.0, *) {
            content
                // Hide system scroll background so our SwiftUI background shows
                .scrollContentBackground(.hidden)
                // Reactive SwiftUI background (updates when theme changes)
                .background(Color.appBackground.ignoresSafeArea())
                .onChange(of: settings.theme) { _ in
                    refreshTableViews()
                }
        } else {
            content
                .background(Color.appBackground.ignoresSafeArea())
                .onChange(of: settings.theme) { _ in
                    refreshTableViews()
                }
        }
    }

    private func updateCellAppearance() {
        let cardColor = UIColor(Color(hex: settings.currentTheme.cardBackgroundHex))
        UITableViewCell.appearance().backgroundColor = cardColor
    }

    private func refreshTableViews() {
        // Update appearance proxy with new colors
        let cardColor = UIColor(Color(hex: settings.currentTheme.cardBackgroundHex))
        UITableViewCell.appearance().backgroundColor = cardColor

        // Force existing table views to pick up new cell colors
        DispatchQueue.main.async {
            UIApplication.shared.windows.forEach { window in
                window.subviews.forEach { subview in
                    subview.removeFromSuperview()
                    window.addSubview(subview)
                }
            }
        }
    }
}

extension View {
    func themedForm() -> some View {
        modifier(ThemedFormModifier())
    }
}
