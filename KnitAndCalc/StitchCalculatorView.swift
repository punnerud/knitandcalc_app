import SwiftUI

struct StitchCalculatorView: View {
    @State private var currentMode: StitchMode = .increase
    @State private var knittingStyle: KnittingStyle = .flat
    @State private var stitchesOnNeedle: String = "20"
    @State private var changes: String = "11"
    @State private var groupTexts: [String] = []
    @State private var groupCounts: [Int] = []
    @State private var checkedSubSteps: [Bool] = []
    @State private var currentStep: Int = 0
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

    enum KnittingStyle: String, CaseIterable {
        case flat = "Flatt"
        case circular = "Rundt"

        var localizedName: LocalizedStringKey {
            switch self {
            case .flat: return "Flatt"
            case .circular: return "Rundt"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Mode selector (Øke/Felle)
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

                // Knitting style selector (Flatt/Rundt)
                HStack(spacing: 8) {
                    ForEach(KnittingStyle.allCases, id: \.self) { style in
                        Button(action: {
                            knittingStyle = style
                            showResult = false
                        }) {
                            Text(style.localizedName)
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(knittingStyle == style ?
                                    Color.appButtonBackgroundSelected.opacity(0.7) :
                                    Color.appButtonBackgroundUnselected)
                                .foregroundColor(knittingStyle == style ? .appButtonText : .appButtonTextUnselected)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                // Input fields
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(knittingStyle == .flat ? "Antall masker på pinnen:" : "Antall masker i omgangen:")
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
                        // Step-by-step navigation
                        if totalSubSteps > 1 {
                            HStack {
                                Button(action: stepBackward) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(currentStep > 0 ? .appIconTint : .appTertiaryText)
                                }
                                .disabled(currentStep <= 0)

                                Spacer()

                                Text(String(format: NSLocalizedString("stitch.step_of", comment: ""), currentStep + 1, totalSubSteps))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)

                                Spacer()

                                Button(action: stepForward) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(currentStep < totalSubSteps - 1 ? .appIconTint : .appTertiaryText)
                                }
                                .disabled(currentStep >= totalSubSteps - 1)
                            }
                            .padding(.bottom, 4)
                        }

                        // Instruction groups with sub-step progress
                        ForEach(0..<groupTexts.count, id: \.self) { groupIndex in
                            let startIdx = groupStartIndex(for: groupIndex)
                            let count = groupCounts[groupIndex]
                            let checkedCount = (startIdx..<startIdx + count).filter { checkedSubSteps[$0] }.count
                            let allChecked = checkedCount == count
                            let isActiveGroup = currentStep >= startIdx && currentStep < startIdx + count

                            Button(action: {
                                jumpToGroup(groupIndex)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: allChecked ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 22))
                                            .foregroundColor(allChecked ?
                                                Color.appCheckmarkActive :
                                                Color.appCheckmarkInactive)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(groupTexts[groupIndex])
                                                .font(.system(size: 16))
                                                .foregroundColor(.appText)
                                                .strikethrough(allChecked, color: .appSecondaryText)
                                                .opacity(allChecked ? 0.5 : 1.0)
                                                .frame(maxWidth: .infinity, alignment: .leading)

                                            if count > 1 {
                                                HStack(spacing: 3) {
                                                    // Sub-step dots (max 20, otherwise just text)
                                                    if count <= 20 {
                                                        ForEach(0..<count, id: \.self) { i in
                                                            let subIdx = startIdx + i
                                                            Circle()
                                                                .fill(checkedSubSteps[subIdx] ?
                                                                    Color.appIconTint :
                                                                    (subIdx == currentStep ?
                                                                        Color.appIconTint.opacity(0.4) :
                                                                        Color.appSecondaryText.opacity(0.2)))
                                                                .frame(width: 8, height: 8)
                                                        }
                                                    }
                                                    Text("\(checkedCount)/\(count)")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.appSecondaryText)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isActiveGroup && !allChecked ?
                                            Color.appIconTint.opacity(0.12) :
                                            Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
        .navigationTitle(NSLocalizedString("menu.stitch_calculator", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UsageStatisticsManager.shared.recordStitchCalculatorOpen()
        }
    }

    func calculate() {
        isFocused = false

        guard let S = Int(stitchesOnNeedle),
              let D = Int(changes),
              S >= 0,
              D >= 0 else {
            return
        }

        // No changes case
        if D == 0 {
            let actionText = currentMode == .increase ? NSLocalizedString("stitch.increases", comment: "") : NSLocalizedString("stitch.decreases", comment: "")
            groupTexts = [String(format: NSLocalizedString("stitch.no_changes", comment: ""), actionText, S)]
            groupCounts = [1]
            checkedSubSteps = [false]
            currentStep = 0
            totalStitches = ""
            showResult = true
            return
        }

        let isDecrease = (currentMode == .decrease)
        let isFlat = (knittingStyle == .flat)

        if isDecrease {
            let maxDecrease = S / 2
            if D > maxDecrease {
                groupTexts = [String(format: NSLocalizedString("stitch.too_many_decreases", comment: ""), S, maxDecrease)]
                groupCounts = [1]
                checkedSubSteps = [false]
                currentStep = 0
                totalStitches = ""
                showResult = true
                return
            }
        }

        // Calculate total stitches to distribute
        // For decrease: each "strikk 2 sammen" consumes 2 stitches from the total
        let totalSts = isDecrease ? (S - 2 * D) : S

        if totalSts < 0 {
            groupTexts = [String(localized: "Ikke nok masker for denne beregningen.")]
            groupCounts = [1]
            checkedSubSteps = [false]
            currentStep = 0
            totalStitches = ""
            showResult = true
            return
        }

        // Key difference: flat = changes + 1 segments, circular = changes segments
        let segmentsCount = isFlat ? D + 1 : D

        guard segmentsCount > 0 else { return }

        let base = totalSts / segmentsCount
        let remainder = totalSts % segmentsCount

        // Bresenham-like distribution for even spreading of remainder
        var segments = Array(repeating: base, count: segmentsCount)
        var err = 0
        for i in 0..<segmentsCount {
            err += remainder
            if err >= segmentsCount {
                segments[i] += 1
                err -= segmentsCount
            }
        }

        // Build instruction sequence
        var seq: [String] = []
        for i in 0..<segments.count {
            let isLastSegment = isFlat && (i == segments.count - 1)
            if isLastSegment {
                // Last segment in flat mode: just knit remaining stitches, no action
                if segments[i] > 0 {
                    let word = segments[i] == 1 ? NSLocalizedString("stitch.stitch_singular", comment: "") : NSLocalizedString("stitch.stitch_plural", comment: "")
                    seq.append(String(format: NSLocalizedString("stitch.knit_x", comment: ""), segments[i], word))
                }
            } else {
                seq.append(instruksjonTekst(mode: currentMode, knitBefore: segments[i]))
            }
        }

        // Group consecutive identical instructions
        let grouped = groupRuns(seq)
        groupTexts = grouped.map { g in
            let timesWord = g.count == 1 ? NSLocalizedString("stitch.time_singular", comment: "") : NSLocalizedString("stitch.time_plural", comment: "")
            return "\(g.text) — \(g.count) \(timesWord)"
        }
        groupCounts = grouped.map { $0.count }
        let total = groupCounts.reduce(0, +)
        checkedSubSteps = Array(repeating: false, count: total)
        currentStep = 0

        let newTotal = isDecrease ? (S - D) : (S + D)
        let stitchWord = knittingStyle == .flat ? NSLocalizedString("stitch.the_needle", comment: "") : NSLocalizedString("stitch.the_round", comment: "")
        totalStitches = String(format: NSLocalizedString("stitch.you_now_have", comment: ""), newTotal, stitchWord)
        showResult = true
    }

    var totalSubSteps: Int {
        checkedSubSteps.count
    }

    func groupStartIndex(for groupIndex: Int) -> Int {
        groupCounts[0..<groupIndex].reduce(0, +)
    }

    func stepForward() {
        guard totalSubSteps > 0 else { return }
        if currentStep < totalSubSteps {
            checkedSubSteps[currentStep] = true
            if let next = (currentStep + 1..<totalSubSteps).first(where: { !checkedSubSteps[$0] }) {
                currentStep = next
            } else {
                currentStep = min(currentStep + 1, totalSubSteps - 1)
            }
        }
    }

    func stepBackward() {
        guard totalSubSteps > 0 else { return }
        if currentStep > 0 {
            if checkedSubSteps[currentStep] {
                checkedSubSteps[currentStep] = false
            } else {
                currentStep -= 1
                checkedSubSteps[currentStep] = false
            }
        } else {
            checkedSubSteps[0] = false
        }
    }

    func jumpToGroup(_ groupIndex: Int) {
        let startIdx = groupStartIndex(for: groupIndex)
        let count = groupCounts[groupIndex]
        let endIdx = startIdx + count
        let allChecked = (startIdx..<endIdx).allSatisfy { checkedSubSteps[$0] }

        if allChecked {
            // Uncheck all in group, jump there
            for i in startIdx..<endIdx {
                checkedSubSteps[i] = false
            }
            currentStep = startIdx
        } else {
            // Check all in group, advance to next unchecked
            for i in startIdx..<endIdx {
                checkedSubSteps[i] = true
            }
            if let next = (endIdx..<totalSubSteps).first(where: { !checkedSubSteps[$0] }) {
                currentStep = next
            } else if let next = (0..<totalSubSteps).first(where: { !checkedSubSteps[$0] }) {
                currentStep = next
            } else {
                currentStep = max(0, totalSubSteps - 1)
            }
        }
    }

    func instruksjonTekst(mode: StitchMode, knitBefore: Int) -> String {
        if mode == .decrease {
            if knitBefore <= 0 { return NSLocalizedString("stitch.k2tog", comment: "") }
            if knitBefore == 1 { return String(format: NSLocalizedString("stitch.k1_k2tog", comment: ""), 1) }
            return String(format: NSLocalizedString("stitch.kn_k2tog", comment: ""), knitBefore)
        } else {
            if knitBefore <= 0 { return NSLocalizedString("stitch.inc1", comment: "") }
            if knitBefore == 1 { return String(format: NSLocalizedString("stitch.k1_inc1", comment: ""), 1) }
            return String(format: NSLocalizedString("stitch.kn_inc1", comment: ""), knitBefore)
        }
    }

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
