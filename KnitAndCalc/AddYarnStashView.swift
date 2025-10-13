//
//  AddYarnStashView.swift
//  KnitAndCalc
//
//  Add new yarn stash entry view
//

import SwiftUI

struct AddYarnStashView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    @ObservedObject private var settings = AppSettings.shared
    var projects: Binding<[Project]>? = nil
    var linkToProjectId: UUID? = nil
    var onYarnCreated: ((YarnStashEntry) -> Void)?

    private static var newBrandKey: String { String(localized: "(Nytt merke)") }
    private static var newTypeKey: String { String(localized: "(Ny type)") }

    @State private var selectedBrand: String = AddYarnStashView.newBrandKey
    @State private var selectedType: String = AddYarnStashView.newTypeKey
    @State private var customBrand: String = ""
    @State private var customType: String = ""
    @State private var showCustomBrandField: Bool = true
    @State private var showCustomTypeField: Bool = true
    @State private var weightPerSkein: String = ""
    @State private var lengthPerSkein: String = ""
    @State private var numberOfSkeins: String = ""
    @State private var totalWeight: String = ""
    @State private var color: String = ""
    @State private var colorNumber: String = ""
    @State private var lotNumber: String = ""
    @State private var notes: String = ""
    @State private var selectedGauge: GaugeOption = .none
    @State private var linkToProject: Bool = false
    @State private var quantity: String = ""
    @State private var quantityType: YarnQuantityType = .skeins
    @FocusState private var isCustomBrandFocused: Bool
    @FocusState private var focusedField: FormField?
    @State private var isUpdatingWeight: Bool = false
    @State private var isUpdatingSkeins: Bool = false

    enum FormField {
        case customBrand, weightPerSkein, lengthPerSkein, numberOfSkeins, totalWeight, color, colorNumber, lotNumber, notes, quantity
    }

    var existingBrands: [String] {
        Array(Set(yarnEntries.map { $0.brand })).sorted()
    }

    var brandsWithNew: [String] {
        [Self.newBrandKey] + existingBrands
    }

    var existingTypesForBrand: [String] {
        let brand = selectedBrand == Self.newBrandKey ? customBrand : selectedBrand
        if brand.isEmpty {
            return []
        }
        return Array(Set(yarnEntries.filter { $0.brand == brand }.map { $0.type })).sorted()
    }

    var typesWithNew: [String] {
        [Self.newTypeKey] + existingTypesForBrand
    }

    var finalBrand: String {
        selectedBrand == Self.newBrandKey ? customBrand : selectedBrand
    }

    var finalType: String {
        selectedType == Self.newTypeKey ? customType : selectedType
    }

    var isFormValid: Bool {
        let basicValid = !finalBrand.isEmpty &&
        !finalType.isEmpty &&
        Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(lengthPerSkein.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) != nil

        if linkToProjectId != nil && linkToProject {
            let quantityValid = Double(quantity.replacingOccurrences(of: ",", with: ".")) != nil &&
                               Double(quantity.replacingOccurrences(of: ",", with: "."))! > 0
            return basicValid && quantityValid
        }
        return basicValid
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Merke")) {
                    Picker("Merke", selection: $selectedBrand) {
                        ForEach(brandsWithNew, id: \.self) { brand in
                            Text(brand).tag(brand)
                        }
                    }
                    .onChange(of: selectedBrand) { newValue in
                        if newValue == Self.newBrandKey {
                            showCustomBrandField = true
                            selectedType = Self.newTypeKey
                        } else {
                            showCustomBrandField = false
                            customBrand = ""
                            // Reset type when brand changes
                            if !existingTypesForBrand.contains(selectedType) {
                                selectedType = Self.newTypeKey
                            }
                        }
                    }

                    if showCustomBrandField {
                        TextField("Skriv inn merke", text: $customBrand)
                            .focused($focusedField, equals: .customBrand)
                    }
                }

                if !finalBrand.isEmpty {
                    Section(header: Text("Type")) {
                        Picker("Type", selection: $selectedType) {
                            ForEach(typesWithNew, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .onChange(of: selectedType) { newValue in
                            showCustomTypeField = (newValue == Self.newTypeKey)
                        }

                        if showCustomTypeField {
                            TextField("Skriv inn type", text: $customType)
                        }
                    }
                }

                Section(header: Text("Garninformasjon")) {
                    HStack {
                        Text(settings.currentUnitSystem == .metric ? "Vekt per nøste (g)" : "Vekt per nøste (oz)")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $weightPerSkein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .weightPerSkein)
                            .onChange(of: weightPerSkein) { _ in
                                updateTotalWeight()
                            }
                    }

                    HStack {
                        Text(settings.currentUnitSystem == .metric ? "Lengde per nøste (m)" : "Lengde per nøste (yd)")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $lengthPerSkein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .lengthPerSkein)
                    }

                    HStack {
                        Text("Antall nøster")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $numberOfSkeins)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .numberOfSkeins)
                            .onChange(of: numberOfSkeins) { _ in
                                if !isUpdatingSkeins {
                                    updateTotalWeight()
                                }
                            }
                    }

                    HStack {
                        Text(settings.currentUnitSystem == .metric ? "Vekt i gram" : "Vekt i oz")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $totalWeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .totalWeight)
                            .onChange(of: focusedField) { newFocus in
                                if newFocus != .totalWeight && !isUpdatingWeight && !totalWeight.isEmpty {
                                    updateNumberOfSkeinsFromWeight()
                                }
                            }
                    }

                    HStack {
                        Text("Farge")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $color)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .color)
                    }

                    HStack {
                        Text("Fargenummer")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $colorNumber)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .colorNumber)
                    }

                    HStack {
                        Text("Innfarging/Partinummer")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $lotNumber)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .lotNumber)
                    }
                }

                Section(header: Text("Strikkefasthet")) {
                    Picker("Strikkefasthet", selection: $selectedGauge) {
                        ForEach(GaugeOption.allCases, id: \.self) { gauge in
                            Text(gauge.displayName).tag(gauge)
                        }
                    }
                }

                Section(header: Text("Notater")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .notes)
                }

                if linkToProjectId != nil, projects != nil {
                    Section(header: Text("Knytt til prosjekt")) {
                        Toggle("Legg til i prosjekt", isOn: $linkToProject)

                        if linkToProject {
                            Picker("Type", selection: $quantityType) {
                                ForEach(YarnQuantityType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            TextField("Mengde", text: $quantity)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .quantity)
                        }
                    }
                }
            }
            .navigationTitle("Nytt garn")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if linkToProjectId != nil {
                    linkToProject = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .customBrand
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { saveYarn() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .appIconTint : .appTertiaryText)
                }
            }
        }
    }

    func updateTotalWeight() {
        guard let weight = Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")),
              let count = Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        let total = weight * count
        isUpdatingWeight = true
        totalWeight = String(format: "%.0f", total)
        isUpdatingWeight = false
    }

    func updateNumberOfSkeinsFromWeight() {
        guard let weight = Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")),
              let total = Double(totalWeight),
              weight > 0 else {
            return
        }
        let count = total / weight
        isUpdatingSkeins = true
        numberOfSkeins = String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        isUpdatingSkeins = false
    }

    func saveYarn() {
        guard let weight = Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")),
              let length = Double(lengthPerSkein.replacingOccurrences(of: ",", with: ".")),
              let count = Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        // Convert from imperial to metric if needed
        let weightInGrams = settings.currentUnitSystem == .imperial ? UnitConverter.ouncesToGrams(weight) : weight
        let lengthInMeters = settings.currentUnitSystem == .imperial ? UnitConverter.yardsToMeters(length) : length

        let yarn = YarnStashEntry(
            brand: finalBrand,
            type: finalType,
            weightPerSkein: weightInGrams,
            lengthPerSkein: lengthInMeters,
            numberOfSkeins: count,
            color: color,
            colorNumber: colorNumber,
            lotNumber: lotNumber,
            notes: notes,
            gauge: selectedGauge
        )

        yarnEntries.append(yarn)

        // Link to project if requested
        if linkToProject,
           let projectId = linkToProjectId,
           let projectsBinding = projects,
           let quantityValue = Double(quantity),
           quantityValue > 0,
           let projectIndex = projectsBinding.wrappedValue.firstIndex(where: { $0.id == projectId }) {

            let projectYarn = ProjectYarn(
                yarnStashId: yarn.id,
                quantityType: quantityType,
                quantity: quantityValue
            )

            projectsBinding.wrappedValue[projectIndex].linkedYarns.append(projectYarn)
        }

        onYarnCreated?(yarn)
        dismiss()
    }
}

#Preview {
    AddYarnStashView(yarnEntries: .constant([]))
}