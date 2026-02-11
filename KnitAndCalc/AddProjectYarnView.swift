//
//  AddProjectYarnView.swift
//  KnitAndCalc
//
//  View for adding yarn to a project
//

import SwiftUI

struct AddProjectYarnView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var projects: [Project]
    let projectId: UUID

    @ObservedObject private var settings = AppSettings.shared
    @State private var yarnEntries: [YarnStashEntry] = []
    @State private var selectedYarnId: UUID?
    @State private var quantity: String = ""
    @State private var quantityType: YarnQuantityType = .skeins
    @State private var showCreateYarn: Bool = false

    var availableYarnEntries: [YarnStashEntry] {
        yarnEntries.filter { $0.numberOfSkeins > 0 }
    }

    var selectedYarn: YarnStashEntry? {
        yarnEntries.first { $0.id == selectedYarnId }
    }

    var isFormValid: Bool {
        selectedYarnId != nil && Double(quantity) != nil && Double(quantity)! > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Velg garn")) {
                    if availableYarnEntries.isEmpty {
                        Text("Ingen garn på lager")
                            .foregroundColor(.appSecondaryText)
                    } else {
                        Picker("Garn", selection: $selectedYarnId) {
                            Text("Velg garn").tag(nil as UUID?)
                            ForEach(availableYarnEntries) { yarn in
                                let totalGrams = Double(yarn.numberOfSkeins) * yarn.weightPerSkein
                                let colorText = yarn.color.isEmpty ? "" : " - \(yarn.color)"
                                Text("\(yarn.brand) \(yarn.type)\(colorText) (\(Int(totalGrams))g)")
                                    .tag(yarn.id as UUID?)
                            }
                        }
                    }

                    Button(action: { showCreateYarn = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.appIconTint)
                            Text("Opprett nytt garn")
                                .foregroundColor(.primary)
                        }
                    }
                }

                if selectedYarn != nil {
                    Section(header: Text("Mengde")) {
                        Picker("Type", selection: $quantityType) {
                            ForEach(YarnQuantityType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        TextField(text: $quantity) {
                            Text(quantityType.displayName)
                        }
                        .keyboardType(.decimalPad)

                        if let quantityValue = Double(quantity),
                           quantityValue > 0,
                           let yarn = selectedYarn {
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                    .padding(.vertical, 4)

                                Text("Garninformasjon")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appSecondaryText)

                                HStack {
                                    Text("På lager:")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)
                                    Spacer()
                                    Text("\(formatNorwegian(yarn.numberOfSkeins)) \(String(localized: "nøster")) (\(UnitConverter.formatWeight(Double(yarn.numberOfSkeins) * yarn.weightPerSkein, unit: settings.currentUnitSystem)))")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.appText)
                                }

                                Divider()
                                    .padding(.vertical, 4)

                                Text("Du reserverer")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appSecondaryText)

                                let calculations = calculateConversions(quantityValue, yarn)

                                if quantityType != .skeins {
                                    HStack {
                                        Text("Nøster:")
                                            .font(.system(size: 13))
                                            .foregroundColor(.appSecondaryText)
                                        Spacer()
                                        Text(formatNorwegian(calculations.skeins))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.appText)
                                    }
                                }

                                if quantityType != .meters {
                                    HStack {
                                        Text(settings.currentUnitSystem == .metric ? "Meter:" : "Yards:")
                                            .font(.system(size: 13))
                                            .foregroundColor(.appSecondaryText)
                                        Spacer()
                                        Text(UnitConverter.formatLength(calculations.meters, unit: settings.currentUnitSystem))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.appText)
                                    }
                                }

                                if quantityType != .grams {
                                    HStack {
                                        Text(settings.currentUnitSystem == .metric ? "Gram:" : "Ounces:")
                                            .font(.system(size: 13))
                                            .foregroundColor(.appSecondaryText)
                                        Spacer()
                                        Text(UnitConverter.formatWeight(calculations.grams, unit: settings.currentUnitSystem))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.appText)
                                    }
                                }

                                HStack {
                                    Text("Prosent av lager:")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)
                                    Spacer()
                                    Text("\(Int(calculations.percentage))%")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(calculations.percentage > 100 ? .red : .appIconTint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Legg til garn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { addYarnToProject() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .appIconTint : .appTertiaryText)
                }
            }
        }
        .sheet(isPresented: $showCreateYarn, onDismiss: {
            let oldIds = Set(yarnEntries.map { $0.id })
            loadYarnEntries()
            // Auto-select newly created yarn and set quantity to 100%
            if let newYarn = yarnEntries.first(where: { !oldIds.contains($0.id) }) {
                selectedYarnId = newYarn.id
                quantityType = .skeins
                quantity = formatNorwegian(newYarn.numberOfSkeins)
            }
        }) {
            AddYarnStashView(
                yarnEntries: Binding(
                    get: { yarnEntries },
                    set: { newValue in
                        yarnEntries = newValue
                        saveYarnEntries()
                    }
                ),
                projects: $projects,
                linkToProjectId: projectId
            )
        }
        .onAppear {
            loadYarnEntries()
        }
    }

    func loadYarnEntries() {
        if let decoded = DataPersistenceManager.shared.load([YarnStashEntry].self, forKey: .yarnStash) {
            yarnEntries = decoded
        }
    }

    func saveYarnEntries() {
        DataPersistenceManager.shared.save(yarnEntries, forKey: .yarnStash)
    }

    func calculateConversions(_ quantityValue: Double, _ yarn: YarnStashEntry) -> (skeins: Double, meters: Double, grams: Double, percentage: Double) {
        let grams: Double
        let meters: Double
        let skeins: Double

        switch quantityType {
        case .grams:
            grams = quantityValue
            skeins = grams / yarn.weightPerSkein
            meters = grams * (yarn.lengthPerSkein / yarn.weightPerSkein)
        case .skeins:
            skeins = quantityValue
            grams = skeins * yarn.weightPerSkein
            meters = skeins * yarn.lengthPerSkein
        case .meters:
            meters = quantityValue
            grams = meters * (yarn.weightPerSkein / yarn.lengthPerSkein)
            skeins = grams / yarn.weightPerSkein
        }

        let totalAvailableGrams = Double(yarn.numberOfSkeins) * yarn.weightPerSkein
        let percentage = (grams / totalAvailableGrams) * 100

        return (skeins, meters, grams, percentage)
    }

    func addYarnToProject() {
        guard let selectedYarnId = selectedYarnId,
              let quantityValue = Double(quantity),
              quantityValue > 0,
              let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }

        let projectYarn = ProjectYarn(
            yarnStashId: selectedYarnId,
            quantityType: quantityType,
            quantity: quantityValue
        )

        projects[projectIndex].linkedYarns.append(projectYarn)

        dismiss()
    }

    func formatNorwegian(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
}

#Preview {
    AddProjectYarnView(
        projects: .constant([Project(name: "Test")]),
        projectId: UUID()
    )
}