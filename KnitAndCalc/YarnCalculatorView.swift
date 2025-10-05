import SwiftUI

struct YarnCalculatorView: View {
    @State private var selectedUnit: YarnUnit = .meter
    @State private var lengthRecipe: String = ""
    @State private var countRecipe: String = ""
    @State private var lengthYours: String = ""
    @State private var resultText: String = ""
    @State private var showResult: Bool = false
    @FocusState private var isFocused: Bool
    @State private var showTensionSettings: Bool = false
    @State private var tensionEnabled: Bool = false
    @State private var tensionFrom: String = ""
    @State private var tensionTo: String = ""

    enum YarnUnit: String, CaseIterable {
        case meter = "Meter"
        case yards = "Yards"

        var abbreviation: String {
            switch self {
            case .meter: return "m"
            case .yards: return "yards"
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                // Description
                Text("Finn ut hvor mye garn du trenger når du bytter til et annet med forskjellig løpelengde. Husk at strikkefastheten skal være lik.")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
                    .padding(.horizontal)

                // Unit selector
                HStack(spacing: 8) {
                    ForEach(YarnUnit.allCases, id: \.self) { unit in
                        Button(action: {
                            selectedUnit = unit
                            showResult = false
                        }) {
                            Text(unit.rawValue)
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedUnit == unit ?
                                    Color.appButtonBackgroundSelected :
                                    Color.appButtonBackgroundUnselected)
                                .foregroundColor(selectedUnit == unit ?
                                    .appButtonText :
                                    .appButtonTextUnselected)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                // Recipe section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Garnet i oppskriften")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appText)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Løpelengde per nøste")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        TextField("", text: $lengthRecipe)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($isFocused)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Antall nøster i oppskriften")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        TextField("", text: $countRecipe)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($isFocused)
                    }
                }
                .padding(.horizontal)

                // Your yarn section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Garnet du vil bruke")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appText)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Løpelengde per nøste")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        TextField("", text: $lengthYours)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($isFocused)
                            .onChange(of: isFocused) { focused in
                                if focused {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            proxy.scrollTo("calculateButton", anchor: .bottom)
                                        }
                                    }
                                }
                            }
                    }

                    Button(action: { calculate(scrollProxy: proxy) }) {
                        Text("Beregn")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appButtonText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appButtonBackground)
                            .cornerRadius(8)
                    }
                    .id("calculateButton")

                    // Tension hint - only show before calculation
                    if !showResult {
                        if !tensionEnabled {
                            Text("💡 Du kan legge til strikkefasthetsberegning under tannhjulet øverst til høyre.")
                                .font(.system(size: 13))
                                .foregroundColor(.appHintText)
                                .padding(.top, 8)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appHintText)
                                Text("Strikkefasthetsberegning er aktivert")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appHintText)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal)

                // Result
                if showResult {
                    VStack(spacing: 16) {
                        Text("🧶🧶🧶")
                            .font(.system(size: 48))
                        Text(resultText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.appResultBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .id("result")
                }
            }
            .padding(.vertical)
            }
            .navigationTitle("Garnkalkulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showTensionSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.appIconTint)
                    }
                }
            }
            .sheet(isPresented: $showTensionSettings) {
                TensionSettingsView(
                    tensionEnabled: $tensionEnabled,
                    tensionFrom: $tensionFrom,
                    tensionTo: $tensionTo
                )
            }
        }
    }

    func calculate(scrollProxy: ScrollViewProxy) {
        // Hide keyboard
        isFocused = false
        guard let lengthRec = Double(lengthRecipe.replacingOccurrences(of: ",", with: ".")),
              let countRec = Double(countRecipe.replacingOccurrences(of: ",", with: ".")),
              let lengthYour = Double(lengthYours.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        if lengthRec <= 0 || countRec <= 0 || lengthYour <= 0 {
            return
        }

        var totalYarn = lengthRec * countRec
        var tensionPercentage: Double? = nil

        // Apply tension adjustment if enabled
        if tensionEnabled,
           let tensionFromVal = Double(tensionFrom.replacingOccurrences(of: ",", with: ".")),
           let tensionToVal = Double(tensionTo.replacingOccurrences(of: ",", with: ".")),
           tensionFromVal > 0, tensionToVal > 0 {
            // Adjust yarn amount based on tension difference
            // More stitches per 10cm = tighter tension = needs more yarn
            let tensionRatio = tensionToVal / tensionFromVal
            totalYarn = totalYarn * tensionRatio

            // Calculate percentage difference
            tensionPercentage = (tensionRatio - 1.0) * 100
        }

        let skeinsNeeded = totalYarn / lengthYour

        var result = "Du trenger \(String(format: "%.1f", skeinsNeeded)) nøster med løpelengde \(String(format: "%.0f", lengthYour))\(selectedUnit.abbreviation)"

        if let percentage = tensionPercentage {
            let sign = percentage >= 0 ? "+" : ""
            result += " (\(sign)\(String(format: "%.0f", percentage))% pga. strikkefasthet)"
        }

        resultText = result
        showResult = true

        // Scroll to result after a short delay to let the view update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy.scrollTo("result", anchor: .bottom)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.appTextFieldBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appTextFieldBorder, lineWidth: 2)
            )
            .foregroundColor(.appTextFieldText)
    }
}

struct TensionSettingsView: View {
    @Binding var tensionEnabled: Bool
    @Binding var tensionFrom: String
    @Binding var tensionTo: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Toggle
                    Toggle(isOn: $tensionEnabled) {
                        Text("Aktiver strikkefasthetsberegning")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appText)
                    }
                    .tint(Color.appButtonBackground)
                    .padding(.horizontal)

                    if tensionEnabled {
                        VStack(alignment: .leading, spacing: 20) {
                            // Info text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hvordan måle strikkefasthet:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appText)

                                Text("Strikk en prøvelapp på minst 12x12 cm. La den ligge flatt og tell masker på 10 cm i bredden. Oppgi antall masker med komma for halve masker (f.eks. 18,5).")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondaryText)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.appResultBackground)
                            .cornerRadius(8)

                            // From tension
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Masker per 10cm i oppskriften")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appSecondaryText)
                                TextField("", text: $tensionFrom)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .focused($isFocused)
                            }

                            // To tension
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Masker per 10cm med ditt garn")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appSecondaryText)
                                TextField("", text: $tensionTo)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .focused($isFocused)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ferdig") {
                        dismiss()
                    }
                    .foregroundColor(.appIconTint)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        YarnCalculatorView()
    }
}