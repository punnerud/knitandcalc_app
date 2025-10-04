import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: YarnCalculatorView()) {
                    CalculatorRow(title: "Garnkalkulator", icon: "🧶")
                }

                NavigationLink(destination: StitchCalculatorView()) {
                    CalculatorRow(title: "Strikkekalkulator", icon: "✨")
                }
            }
            .navigationTitle("Knit&Calc")
            .listStyle(InsetGroupedListStyle())
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