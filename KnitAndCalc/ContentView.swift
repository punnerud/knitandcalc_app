//
//  ContentView.swift
//  KnitAndCalc
//
//  Created by Morten Punnerud-Engelstad on 30/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showAdvanced: Bool = false
    @State private var currentMessage: AppMessage? = nil

    var body: some View {
        NavigationView {
            List {
                // In-app message banner
                if let message = currentMessage {
                    Section {
                        MessageBannerView(message: message) {
                            MessageService.shared.dismissMessage(id: message.id)
                            withAnimation { currentMessage = nil }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }

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

                Section {
                    DisclosureGroup(isExpanded: $showAdvanced) {
                        NavigationLink(destination: YarnStockCounterView()) {
                            HStack(spacing: 16) {
                                Text("📦")
                                    .font(.system(size: 24))
                                Text(NSLocalizedString("menu.yarn_stock_count", comment: ""))
                                    .font(.system(size: 16))
                                    .foregroundColor(.appText)
                            }
                            .padding(.vertical, 4)
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Text("⚙️")
                                .font(.system(size: 32))
                            Text(NSLocalizedString("menu.advanced", comment: ""))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                    }
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
        .onAppear {
            MessageService.shared.checkForMessages { msg in
                currentMessage = msg
            }
        }
    }
}

// MARK: - Message Banner

struct MessageBannerView: View {
    let message: AppMessage
    let onDismiss: () -> Void

    private var backgroundColor: Color {
        switch message.type {
        case "warning": return Color.orange.opacity(0.15)
        case "important": return Color.red.opacity(0.15)
        default: return Color.blue.opacity(0.12)
        }
    }

    private var accentColor: Color {
        switch message.type {
        case "warning": return .orange
        case "important": return .red
        default: return .blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = message.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                if message.url != nil {
                    Text("Trykk for å åpne")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(backgroundColor)
        .onTapGesture {
            if let urlStr = message.url, let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }
        }
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
