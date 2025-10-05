import SwiftUI

struct StitchCalculatorView: View {
    @State private var currentMode: StitchMode = .increase
    @State private var stitchesOnNeedle: String = "20"
    @State private var changes: String = "11"
    @State private var instructionLines: [String] = []
    @State private var checkedLines: [Bool] = []
    @State private var totalStitches: String = ""
    @State private var showResult: Bool = false
    @FocusState private var isFocused: Bool

    enum StitchMode: String, CaseIterable {
        case increase = "Øke"
        case decrease = "Felle"

        var localizedName: LocalizedStringKey {
            switch self {
            case .increase: return "Øke"
            case .decrease: return "Felle"
            }
        }

        var actionWord: String {
            switch self {
            case .increase: return String(localized: "øk")
            case .decrease: return String(localized: "fell")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Mode selector
                HStack(spacing: 8) {
                    ForEach(StitchMode.allCases, id: \.self) { mode in
                        Button(action: {
                            currentMode = mode
                            showResult = false
                        }) {
                            Text(mode.localizedName)
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(currentMode == mode ?
                                    Color.appButtonBackgroundSelected :
                                    Color.appButtonBackgroundUnselected)
                                .foregroundColor(currentMode == mode ? .appButtonText : .appButtonTextUnselected)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                // Input fields
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Antall masker på pinnen:")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        TextField("", text: $stitchesOnNeedle)
                            .keyboardType(.numberPad)
                            .textFieldStyle(StitchTextFieldStyle())
                            .focused($isFocused)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentMode == .increase ? "Antall økninger:" : "Antall fellinger:")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        TextField("", text: $changes)
                            .keyboardType(.numberPad)
                            .textFieldStyle(StitchTextFieldStyle())
                            .focused($isFocused)
                    }
                }
                .padding(.horizontal)

                // Calculate button
                Button(action: calculate) {
                    Text("Beregn")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appButtonText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appButtonBackground)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Result
                if showResult {
                    VStack(alignment: .leading, spacing: 16) {
                        if instructionLines.count > 2 {
                            // Show checkboxes for multiple lines
                            ForEach(0..<instructionLines.count, id: \.self) { index in
                                Button(action: {
                                    checkedLines[index].toggle()
                                }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: checkedLines[index] ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 22))
                                            .foregroundColor(checkedLines[index] ?
                                                Color.appCheckmarkActive :
                                                Color.appCheckmarkInactive)

                                        Text(instructionLines[index])
                                            .font(.system(size: 16))
                                            .foregroundColor(.appText)
                                            .strikethrough(checkedLines[index], color: .appSecondaryText)
                                            .opacity(checkedLines[index] ? 0.5 : 1.0)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            // Show plain text for 1-2 lines
                            ForEach(instructionLines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 16))
                                    .foregroundColor(.appText)
                            }
                        }

                        if !totalStitches.isEmpty {
                            Text(totalStitches)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appResultBackground)
                                .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Strikkekalkulator")
        .navigationBarTitleDisplayMode(.inline)
    }

    func calculate() {
        // Hide keyboard
        isFocused = false

        guard let S = Int(stitchesOnNeedle),
              let D = Int(changes),
              S >= 0,
              D >= 0 else {
            return
        }

        // No changes case
        if D == 0 {
            let actionText = currentMode == .increase ? "økninger" : "fellinger"
            instructionLines = [String(localized: "Ingen \(actionText) valgt. Du har fortsatt \(S) masker på pinnen.")]
            checkedLines = [false]
            totalStitches = ""
            showResult = true
            return
        }

        if currentMode == .decrease {
            // Validation: max fellinger er floor(S/2)
            let maxDecrease = S / 2
            if D > maxDecrease {
                instructionLines = [String(localized: "Du prøver å felle for mange masker. Maks antall fellinger for \(S) masker er \(maxDecrease).")]
                checkedLines = [false]
                totalStitches = ""
                showResult = true
                return
            }

            // Felle-logikk fra HTML
            let totalKnit = S - 2 * D
            let base = totalKnit / D
            let extra = totalKnit % D
            let startExtra = extra / 2
            let endExtra = extra - startExtra
            let middleCount = D - extra

            var seq: [String] = []

            // Start ekstra (base+1)
            for _ in 0..<startExtra {
                seq.append(instruksjonTekst(mode: .decrease, knitBefore: base + 1))
            }
            // Midtre (base)
            for _ in 0..<middleCount {
                seq.append(instruksjonTekst(mode: .decrease, knitBefore: base))
            }
            // Slutt ekstra (base+1)
            for _ in 0..<endExtra {
                seq.append(instruksjonTekst(mode: .decrease, knitBefore: base + 1))
            }

            let grouped = groupRuns(seq)
            instructionLines = grouped.map { g in
                let timesWord = g.count == 1 ? "gang" : "ganger"
                return "*\(g.text)* \(g.count) \(timesWord)"
            }
            checkedLines = Array(repeating: false, count: instructionLines.count)
            totalStitches = String(localized: "Du har nå \(S - D) masker på pinnen")
            showResult = true

        } else { // increase
            // Øke-logikk fra HTML
            let totalKnit = S
            let base = totalKnit / D
            let extra = totalKnit % D
            let startExtra = extra / 2
            let endExtra = extra - startExtra
            let middleCount = D - extra

            var seq: [String] = []

            for _ in 0..<startExtra {
                seq.append(instruksjonTekst(mode: .increase, knitBefore: base + 1))
            }
            for _ in 0..<middleCount {
                seq.append(instruksjonTekst(mode: .increase, knitBefore: base))
            }
            for _ in 0..<endExtra {
                seq.append(instruksjonTekst(mode: .increase, knitBefore: base + 1))
            }

            let grouped = groupRuns(seq)
            instructionLines = grouped.map { g in
                let timesWord = g.count == 1 ? "gang" : "ganger"
                return "*\(g.text)* \(g.count) \(timesWord)"
            }
            checkedLines = Array(repeating: false, count: instructionLines.count)
            totalStitches = String(localized: "Du har nå \(S + D) masker på pinnen")
            showResult = true
        }
    }

    // Lag human-friendly tekst for et repeat-element (fra HTML)
    func instruksjonTekst(mode: StitchMode, knitBefore: Int) -> String {
        if mode == .decrease {
            if knitBefore <= 0 { return "Strikk 2 sammen" }
            if knitBefore == 1 { return "Strikk 1 maske, strikk 2 sammen" }
            return "Strikk \(knitBefore) masker, strikk 2 sammen"
        } else { // increase
            if knitBefore <= 0 { return "Øk 1 maske" }
            if knitBefore == 1 { return "Strikk 1 maske, øk 1 maske" }
            return "Strikk \(knitBefore) masker, øk 1 maske"
        }
    }

    // Funksjon for å slå sammen like instruksjoner til "X ganger" (fra HTML)
    func groupRuns(_ arr: [String]) -> [(text: String, count: Int)] {
        guard !arr.isEmpty else { return [] }
        var out: [(text: String, count: Int)] = []
        var cur = (text: arr[0], count: 1)

        for i in 1..<arr.count {
            if arr[i] == cur.text {
                cur.count += 1
            } else {
                out.append(cur)
                cur = (text: arr[i], count: 1)
            }
        }
        out.append(cur)
        return out
    }
}

struct StitchTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.appTextFieldBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appTextFieldBorder, lineWidth: 1)
            )
            .foregroundColor(.appTextFieldText)
    }
}

#Preview {
    NavigationView {
        StitchCalculatorView()
    }
}