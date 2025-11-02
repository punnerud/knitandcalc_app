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
    @ObservedObject private var locationManager = LocationManager.shared
    var projects: Binding<[Project]>? = nil
    var linkToProjectId: UUID? = nil
    var onYarnCreated: ((YarnStashEntry) -> Void)?
    var detectedInfo: DetectedYarnInfo? = nil

    private static var newBrandKey: String { String(localized: "(Nytt merke)") }
    private static var newTypeKey: String { String(localized: "(Ny type)") }
    private static var newLocationKey: String { String(localized: "(Ny lokasjon)") }

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
    @State private var barcode: String = ""
    @State private var showBarcodeScanner: Bool = false
    @State private var scannedBarcodeCode: String = ""
    @State private var scannedBarcodeText: String = ""
    @State private var notes: String = ""
    @State private var selectedLocation: String = ""
    @State private var customLocation: String = ""
    @State private var showCustomLocationField: Bool = false
    @State private var selectedGauge: GaugeOption = .none
    @State private var customGauge: String = ""
    @State private var linkToProject: Bool = false
    @State private var quantity: String = ""
    @State private var quantityType: YarnQuantityType = .skeins
    @FocusState private var isCustomBrandFocused: Bool
    @FocusState private var focusedField: FormField?
    @State private var isUpdatingWeight: Bool = false
    @State private var isUpdatingSkeins: Bool = false

    enum FormField {
        case customBrand, weightPerSkein, lengthPerSkein, numberOfSkeins, totalWeight, color, colorNumber, lotNumber, barcode, notes, customLocation, quantity, customGauge
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

    var locationsWithNew: [String] {
        locationManager.getLocationsWithNew()
    }

    var finalLocation: String {
        selectedLocation == Self.newLocationKey ? customLocation : selectedLocation
    }

    var isBrandFilled: Bool {
        !finalBrand.isEmpty
    }

    var isTypeFilled: Bool {
        !finalType.isEmpty
    }

    var isWeightFilled: Bool {
        Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var isLengthFilled: Bool {
        Double(lengthPerSkein.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var isSkeinsCountFilled: Bool {
        Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var requiredFieldsCount: Int {
        // Count required fields filled out of 5 total (brand, type, weight, length, number of skeins)
        var count = 0
        if isBrandFilled { count += 1 }
        if isTypeFilled { count += 1 }
        if isWeightFilled { count += 1 }
        if isLengthFilled { count += 1 }
        if isSkeinsCountFilled { count += 1 }
        return count
    }

    var allRequiredFieldsFilled: Bool {
        requiredFieldsCount == 5
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
                Section(header: HStack(spacing: 2) {
                    Text("Merke")
                    if !isBrandFilled && !allRequiredFieldsFilled {
                        Text("*").foregroundColor(.red)
                    }
                }) {
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
                    Section(header: HStack(spacing: 2) {
                        Text("Type")
                        if !isTypeFilled && !allRequiredFieldsFilled {
                            Text("*").foregroundColor(.red)
                        }
                    }) {
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

                Section(header: HStack(spacing: 2) {
                    Text("Garninformasjon")
                    if (!isWeightFilled || !isLengthFilled || !isSkeinsCountFilled) && !allRequiredFieldsFilled {
                        Text("*").foregroundColor(.red)
                    }
                }) {
                    HStack {
                        HStack(spacing: 2) {
                            Text(settings.currentUnitSystem == .metric ? "Vekt per nøste (g)" : "Vekt per nøste (oz)")
                            if !isWeightFilled && !allRequiredFieldsFilled {
                                Text("*").foregroundColor(.red).font(.system(size: 12))
                            }
                        }
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
                        HStack(spacing: 2) {
                            Text(settings.currentUnitSystem == .metric ? "Lengde per nøste (m)" : "Lengde per nøste (yd)")
                            if !isLengthFilled && !allRequiredFieldsFilled {
                                Text("*").foregroundColor(.red).font(.system(size: 12))
                            }
                        }
                        .frame(width: 160, alignment: .leading)
                        TextField("", text: $lengthPerSkein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .lengthPerSkein)
                    }

                    HStack {
                        HStack(spacing: 2) {
                            Text("Antall nøster")
                            if !isSkeinsCountFilled && !allRequiredFieldsFilled {
                                Text("*").foregroundColor(.red).font(.system(size: 12))
                            }
                        }
                        .frame(width: 160, alignment: .leading)
                        TextField("", text: $numberOfSkeins)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .numberOfSkeins)
                            .onChange(of: numberOfSkeins) { _ in
                                if !isUpdatingSkeins {
                                    updateTotalWeight()
                                    updateProjectQuantity()
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
                        if !colorNumber.isEmpty && detectedInfo?.color != nil {
                            Button(action: {
                                colorNumber = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    HStack {
                        Text("Innfarging/Partinummer")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $lotNumber)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .lotNumber)
                        if !lotNumber.isEmpty && detectedInfo?.lotNumber != nil {
                            Button(action: {
                                lotNumber = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    HStack {
                        Text("Strekkode/EAN")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $barcode)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .barcode)
                        if !barcode.isEmpty && detectedInfo?.barcode != nil {
                            Button(action: {
                                barcode = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Button(action: {
                            showBarcodeScanner = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.appIconTint)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section(header: Text("Notater")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .notes)
                }

                Section(header: Text("Lokasjon")) {
                    Picker("Lokasjon", selection: $selectedLocation) {
                        ForEach(locationsWithNew, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                    .onChange(of: selectedLocation) { newValue in
                        showCustomLocationField = (newValue == Self.newLocationKey)
                    }

                    if showCustomLocationField {
                        TextField("Skriv inn lokasjon", text: $customLocation)
                            .focused($focusedField, equals: .customLocation)
                    }
                }

                Section(header: Text("Strikkefasthet")) {
                    Picker("Strikkefasthet", selection: $selectedGauge) {
                        ForEach(GaugeOption.pickerCases, id: \.self) { gauge in
                            Text(gauge.displayName).tag(gauge)
                        }
                    }

                    if selectedGauge == .other {
                        HStack {
                            Text("Angi verdi")
                                .frame(width: 160, alignment: .leading)
                            TextField("", text: $customGauge)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .customGauge)
                        }
                    }
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

                            HStack {
                                Text("Mengde")
                                    .frame(width: 160, alignment: .leading)
                                TextField("", text: $quantity)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .quantity)
                            }

                            // Show percentage of stash
                            if let quantityValue = Double(quantity.replacingOccurrences(of: ",", with: ".")),
                               quantityValue > 0,
                               let weight = Double(weightPerSkein.replacingOccurrences(of: ",", with: ".")),
                               let length = Double(lengthPerSkein.replacingOccurrences(of: ",", with: ".")),
                               let count = Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) {
                                let calculations = calculateProjectYarnConversions(quantityValue, weight, length, count)

                                VStack(alignment: .leading, spacing: 8) {
                                    Divider()
                                        .padding(.vertical, 4)

                                    Text("Du reserverer til prosjektet")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.appSecondaryText)

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
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if linkToProjectId != nil {
                    linkToProject = true
                    // Set quantity to 100% if valid skeins count exists
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        updateProjectQuantity()
                    }
                }

                // Pre-fill from detected info
                if let info = detectedInfo {
                    if let barcodeValue = info.barcode {
                        barcode = barcodeValue
                    }

                    // Clean and validate color number (A-Z, 0-9 only, min 3 chars)
                    if let colorValue = info.color {
                        if let cleaned = cleanAndValidateCode(colorValue) {
                            colorNumber = cleaned
                        }
                    }

                    // Clean and validate lot number (A-Z, 0-9 only, min 3 chars)
                    if let lotValue = info.lotNumber {
                        if let cleaned = cleanAndValidateCode(lotValue) {
                            lotNumber = cleaned
                        }
                    }

                    // Pre-fill brand from EAN company name (preferred)
                    let brandToUse = info.detectedCompany ?? info.brandName

                    if let brandValue = brandToUse {
                        // Try to find matching existing brand
                        if let matchingBrand = existingBrands.first(where: {
                            $0.lowercased().contains(brandValue.lowercased()) ||
                            brandValue.lowercased().contains($0.lowercased())
                        }) {
                            selectedBrand = matchingBrand
                            showCustomBrandField = false
                        } else {
                            customBrand = brandValue
                        }
                    }

                    // Pre-fill type from product name if available
                    if let productName = info.productName {
                        // Try to find matching existing type for the selected brand
                        let typesForBrand = yarnEntries
                            .filter { $0.brand == (showCustomBrandField ? customBrand : selectedBrand) }
                            .map { $0.type }

                        if let matchingType = typesForBrand.first(where: {
                            $0.lowercased().contains(productName.lowercased()) ||
                            productName.lowercased().contains($0.lowercased())
                        }) {
                            selectedType = matchingType
                            showCustomTypeField = false
                        } else {
                            customType = productName
                        }
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if detectedInfo == nil {
                        focusedField = .customBrand
                    } else {
                        // Focus on first empty required field
                        if customBrand.isEmpty && selectedBrand == AddYarnStashView.newBrandKey {
                            focusedField = .customBrand
                        } else if customType.isEmpty && selectedType == AddYarnStashView.newTypeKey {
                            focusedField = .weightPerSkein
                        } else {
                            focusedField = .weightPerSkein
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if requiredFieldsCount > 0 && requiredFieldsCount < 5 {
                        HStack(spacing: 0) {
                            Text("Nytt garn (")
                            Text("\(requiredFieldsCount)/5")
                            Text("*")
                                .foregroundColor(.red)
                            Text(")")
                        }
                        .font(.headline)
                    } else {
                        Text("Nytt garn")
                            .font(.headline)
                    }
                }

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
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    scannedCode: $scannedBarcodeCode,
                    scannedText: $scannedBarcodeText,
                    showOCR: false,
                    onBarcodeScanned: { code in
                        barcode = code
                    }
                )
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

    func calculateProjectYarnConversions(_ quantityValue: Double, _ weight: Double, _ length: Double, _ count: Double) -> (skeins: Double, meters: Double, grams: Double, percentage: Double) {
        let grams: Double
        let meters: Double
        let skeins: Double

        switch quantityType {
        case .grams:
            grams = quantityValue
            skeins = grams / weight
            meters = grams * (length / weight)
        case .skeins:
            skeins = quantityValue
            grams = skeins * weight
            meters = skeins * length
        case .meters:
            meters = quantityValue
            grams = meters * (weight / length)
            skeins = grams / weight
        }

        let totalAvailableGrams = count * weight
        let percentage = (grams / totalAvailableGrams) * 100

        return (skeins, meters, grams, percentage)
    }

    func updateProjectQuantity() {
        // Auto-set quantity to 100% of stash when all required fields are filled
        guard linkToProject,
              let count = Double(numberOfSkeins.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        // Only auto-set if quantity is empty or zero
        let currentQuantity = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        if currentQuantity == 0 {
            quantity = formatNorwegian(count)
        }
    }

    func formatNorwegian(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
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

        // Save new location if needed
        if !finalLocation.isEmpty && !locationManager.locations.contains(finalLocation) {
            locationManager.addLocation(finalLocation)
        }

        let yarn = YarnStashEntry(
            brand: finalBrand,
            type: finalType,
            weightPerSkein: weightInGrams,
            lengthPerSkein: lengthInMeters,
            numberOfSkeins: count,
            color: color,
            colorNumber: colorNumber,
            lotNumber: lotNumber,
            barcode: barcode,
            notes: notes,
            gauge: selectedGauge,
            customGauge: customGauge,
            location: finalLocation
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

    // Clean and validate code (color/lot number): A-Z, 0-9 only, min 3 chars
    func cleanAndValidateCode(_ input: String) -> String? {
        // Strip to only alphanumeric characters (A-Z, 0-9)
        let cleaned = input.filter { $0.isLetter || $0.isNumber }

        // Only return if 3 or more characters
        return cleaned.count >= 3 ? cleaned : nil
    }
}

#Preview {
    AddYarnStashView(yarnEntries: .constant([]))
}