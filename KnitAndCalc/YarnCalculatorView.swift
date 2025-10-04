import SwiftUI

struct YarnCalculatorView: View {
    @State private var selectedUnit: YarnUnit = .meter
    @State private var lengthRecipe: String = ""
    @State private var countRecipe: String = ""
    @State private var lengthYours: String = ""
    @State private var resultText: String = ""
    @State private var showResult: Bool = false
    @FocusState private var isFocused: Bool

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
                    .foregroundColor(Color(white: 0.35))
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
                                    Color(red: 0.75, green: 0.70, blue: 0.85) :
                                    Color(red: 0.93, green: 0.92, blue: 0.95))
                                .foregroundColor(selectedUnit == unit ?
                                    .white :
                                    Color(white: 0.45))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                // Recipe section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Garnet i oppskriften")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(white: 0.17))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Løpelengde per nøste")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.35))
                        TextField("", text: $lengthRecipe)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($isFocused)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Antall nøster i oppskriften")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.35))
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
                        .foregroundColor(Color(white: 0.17))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Løpelengde per nøste")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.35))
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.70, green: 0.65, blue: 0.82))
                            .cornerRadius(8)
                    }
                    .id("calculateButton")
                }
                .padding(.horizontal)

                // Result
                if showResult {
                    VStack(spacing: 16) {
                        Text("🧶🧶🧶")
                            .font(.system(size: 48))
                        Text(resultText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(white: 0.17))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(red: 0.93, green: 0.92, blue: 0.95))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .id("result")
                }
            }
            .padding(.vertical)
            }
            .navigationTitle("Garnkalkulator")
            .navigationBarTitleDisplayMode(.inline)
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

        let totalYarn = lengthRec * countRec
        let skeinsNeeded = totalYarn / lengthYour

        resultText = String(localized: "Du trenger \(String(format: "%.1f", skeinsNeeded)) nøster med løpelengde \(String(format: "%.0f", lengthYour))\(selectedUnit.abbreviation)")
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
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.80, green: 0.75, blue: 0.88), lineWidth: 2)
            )
            .foregroundColor(Color(red: 0.50, green: 0.45, blue: 0.60))
    }
}

#Preview {
    NavigationView {
        YarnCalculatorView()
    }
}