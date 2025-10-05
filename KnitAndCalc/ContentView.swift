//
//  ContentView.swift
//  KnitAndCalc
//
//  Created by Morten Punnerud-Engelstad on 30/09/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ProjectListView()) {
                    CalculatorRow(title: NSLocalizedString("menu.projects", comment: ""), icon: "🧵")
                }

                NavigationLink(destination: YarnStashListView()) {
                    CalculatorRow(title: NSLocalizedString("menu.yarn_stash", comment: ""), icon: "🧶")
                }

                NavigationLink(destination: RecipeListView()) {
                    CalculatorRow(title: NSLocalizedString("menu.recipes", comment: ""), icon: "📝")
                }

                NavigationLink(destination: YarnCalculatorView()) {
                    CalculatorRow(title: NSLocalizedString("menu.yarn_calculator", comment: ""), icon: "🔢")
                }

                NavigationLink(destination: StitchCalculatorView()) {
                    CalculatorRow(title: NSLocalizedString("menu.stitch_calculator", comment: ""), icon: "✨")
                }

                NavigationLink(destination: RulerView()) {
                    CalculatorRow(title: NSLocalizedString("menu.ruler", comment: ""), icon: "📏")
                }
            }
            .navigationTitle("Knit&Calc")
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.appIconTint)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct CalculatorRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
