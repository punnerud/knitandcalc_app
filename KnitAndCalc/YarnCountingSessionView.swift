//
//  YarnCountingSessionView.swift
//  KnitAndCalc
//
//  Yarn counting session for organized inventory
//

import SwiftUI
import VisionKit

struct YarnCountingSessionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var selectedLocation: String = ""
    @State private var newLocationName: String = ""
    @State private var showNewLocationField: Bool = false
    @State private var countedYarnIds: Set<UUID> = []
    @State private var originalYarnStates: [UUID: (location: String, lastChecked: Date?)] = [:]
    @State private var sessionStartTime: Date = Date()

    // Search and filter states
    @State private var selectedBrand: String = ""
    @State private var selectedType: String = ""
    @State private var searchText: String = ""
    @State private var showAddNewYarn: Bool = false

    // Camera scanning states
    @State private var showCameraScanner: Bool = false
    @State private var scannedBarcode: String = ""
    @State private var scannedText: String = ""
    @State private var matchedYarn: YarnStashEntry?
    @State private var showBarcodeUpdateAlert: Bool = false
    @State private var yarnToUpdateBarcode: YarnStashEntry?

    // Quantity input states
    @State private var showQuantityInput: Bool = false
    @State private var yarnToCount: YarnStashEntry?
    @State private var detectedInfoForYarn: DetectedYarnInfo?

    var countedYarns: [YarnStashEntry] {
        yarnEntries.filter { countedYarnIds.contains($0.id) }
    }

    var yarnsInLocation: [YarnStashEntry] {
        yarnEntries.filter { $0.location == selectedLocation }
    }

    var totalWeightInLocation: Double {
        yarnsInLocation.reduce(0.0) { sum, yarn in
            sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
        }
    }

    var locationOptions: [String] {
        var options = [NSLocalizedString("location.new_location_placeholder", comment: "")]
        options.append(contentsOf: locationManager.locations)
        return options
    }

    var availableBrands: [String] {
        Array(Set(yarnEntries.map { $0.brand })).sorted()
    }

    var availableTypes: [String] {
        guard !selectedBrand.isEmpty else { return [] }
        return Array(Set(yarnEntries.filter { $0.brand == selectedBrand }.map { $0.type })).sorted()
    }

    var availableYarns: [YarnStashEntry] {
        var yarns = yarnEntries.filter { !countedYarnIds.contains($0.id) }

        // Filter by brand
        if !selectedBrand.isEmpty {
            yarns = yarns.filter { $0.brand == selectedBrand }
        }

        // Filter by type
        if !selectedType.isEmpty {
            yarns = yarns.filter { $0.type == selectedType }
        }

        // Filter by search text - multi-word search (all words must match)
        if !searchText.isEmpty {
            let searchWords = searchText.split(separator: " ").map { String($0) }
            yarns = yarns.filter { yarn in
                // All searchable fields combined into one string
                let searchableContent = [
                    yarn.brand,
                    yarn.type,
                    yarn.color,
                    yarn.colorNumber,
                    yarn.barcode,
                    yarn.lotNumber,
                    yarn.notes
                ].joined(separator: " ")

                // Check that ALL search words are found in the searchable content
                return searchWords.allSatisfy { word in
                    searchableContent.localizedCaseInsensitiveContains(word)
                }
            }
        }

        return yarns.sorted { ($0.brand, $0.type, $0.color) < ($1.brand, $1.type, $1.color) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Location selection header
                if selectedLocation.isEmpty {
                    locationSelectionView
                } else {
                    // Counting interface
                    countingInterfaceView
                }
            }
            .navigationTitle(selectedLocation.isEmpty ? NSLocalizedString("yarn_stock.start_count", comment: "") : NSLocalizedString("yarn_stock.counting", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedLocation.isEmpty {
                        Button("Avbryt") {
                            dismiss()
                        }
                    } else {
                        Button("Tilbake") {
                            selectedLocation = ""
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedLocation.isEmpty {
                        Button("Ferdig") {
                            finishCounting()
                        }
                        .foregroundColor(.appIconTint)
                        .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showAddNewYarn) {
                AddYarnStashView(
                    yarnEntries: $yarnEntries
                ) { newYarn in
                    addNewYarnToCount(newYarn)
                }
            }
            .sheet(isPresented: $showCameraScanner, onDismiss: {
                // After camera scanner dismisses, show quantity input if yarn was selected
                if yarnToCount != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showQuantityInput = true
                    }
                }
            }) {
                if #available(iOS 16.0, *), DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    LiveCameraScannerView(
                        yarnEntries: $yarnEntries,
                        availableYarns: availableYarns,
                        onYarnSelected: { yarn, detectedInfo in
                            yarnToCount = yarn
                            detectedInfoForYarn = detectedInfo
                            // Don't show quantity input here - wait for camera to dismiss
                        }
                    )
                } else {
                    // Fallback for iOS 15 or unsupported devices
                    BarcodeScannerView(
                        scannedCode: $scannedBarcode,
                        scannedText: $scannedText,
                        showOCR: false,
                        onBarcodeScanned: { code in
                            handleBarcodeScanned(code)
                        }
                    )
                }
            }
            .sheet(isPresented: $showQuantityInput, onDismiss: {
                // Clear yarn selection state when quantity input closes
                // (Note: addYarnToCountWithQuantity also clears this on confirm)
                yarnToCount = nil
                detectedInfoForYarn = nil
            }) {
                if let yarn = yarnToCount {
                    YarnQuantityInputView(
                        yarn: yarn,
                        detectedInfo: detectedInfoForYarn,
                        onConfirm: { skeinsToAdd in
                            addYarnToCountWithQuantity(yarn, quantity: skeinsToAdd, detectedInfo: detectedInfoForYarn)
                        }
                    )
                }
            }
            .alert("Update Barcode", isPresented: $showBarcodeUpdateAlert) {
                Button("Cancel", role: .cancel) {
                    yarnToUpdateBarcode = nil
                    scannedBarcode = ""
                }
                Button("Update") {
                    confirmBarcodeUpdate()
                }
            } message: {
                if let yarn = yarnToUpdateBarcode {
                    if yarn.barcode.isEmpty {
                        Text("Add barcode '\(scannedBarcode)' to \(yarn.brand) \(yarn.type)?")
                    } else {
                        Text("Update barcode from '\(yarn.barcode)' to '\(scannedBarcode)' for \(yarn.brand) \(yarn.type)?")
                    }
                }
            }
        }
    }

    var locationSelectionView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "location.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.appIconTint)
                    .padding(.top, 40)

                Text(NSLocalizedString("location.select_for_count", comment: ""))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appText)

                Text(NSLocalizedString("location.select_location_prompt", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Picker("Lokasjon", selection: Binding(
                    get: {
                        showNewLocationField ? NSLocalizedString("location.new_location_placeholder", comment: "") : selectedLocation
                    },
                    set: { newValue in
                        if newValue == NSLocalizedString("location.new_location_placeholder", comment: "") {
                            showNewLocationField = true
                        } else {
                            showNewLocationField = false
                            selectedLocation = newValue
                        }
                    }
                )) {
                    Text(NSLocalizedString("location.select_location", comment: "")).tag("")
                    ForEach(locationOptions, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                if showNewLocationField {
                    VStack(spacing: 12) {
                        TextField(NSLocalizedString("location.new_location_name", comment: ""), text: $newLocationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            createNewLocation()
                        }) {
                            Text(NSLocalizedString("location.create_and_continue", comment: ""))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(newLocationName.isEmpty ? Color.gray : Color.appIconTint)
                                .cornerRadius(12)
                        }
                        .disabled(newLocationName.isEmpty)
                        .padding(.horizontal)
                    }
                }

                if !selectedLocation.isEmpty && !showNewLocationField {
                    Button(action: {
                        // Location is already selected, this will trigger the view to show counting interface
                    }) {
                        Text("Start telling i '\(selectedLocation)'")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appIconTint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground)
    }

    var countingInterfaceView: some View {
        VStack(spacing: 0) {
            // Session header
            sessionHeaderView

            // Search and filters
            searchAndFilterView

            // Main content - available yarns and counted yarns
            ScrollView {
                VStack(spacing: 0) {
                    // Available yarns section
                    availableYarnsSection

                    // Counted yarns section (only from this session)
                    if !countedYarns.isEmpty {
                        countedYarnsSection
                    }
                }
            }
        }
    }

    var sessionHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedLocation)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appText)

                    Text("Lagt til i økten: \(countedYarnIds.count) garn")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(UnitConverter.formatWeight(totalWeightInLocation, unit: settings.currentUnitSystem))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appIconTint)
                    Text("totalt i lokasjon")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondaryText)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()
        }
        .background(Color.appSecondaryBackground)
    }

    var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Brand filter
            Picker("Merke", selection: $selectedBrand) {
                Text("Alle merker").tag("")
                ForEach(availableBrands, id: \.self) { brand in
                    Text(brand).tag(brand)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedBrand) { _ in
                selectedType = ""
            }

            // Type filter
            if !selectedBrand.isEmpty && !availableTypes.isEmpty {
                Picker("Type", selection: $selectedType) {
                    Text("Alle typer").tag("")
                    ForEach(availableTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
            }

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appSecondaryText)

                TextField("Søk på flere ord (f.eks: sandnes rød)", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appSecondaryText)
                    }
                }

                Button(action: {
                    showCameraScanner = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appIconTint)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(10)
            .background(Color.appButtonBackgroundUnselected)
            .cornerRadius(10)
            .padding(.horizontal)

            Divider()
        }
        .padding(.vertical, 8)
        .background(Color.appSecondaryBackground)
    }

    var availableYarnsSection: some View {
        VStack(spacing: 0) {
            // Section header
            VStack(spacing: 4) {
                HStack {
                    Text("Tilgjengelig garn")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                    Text("\(availableYarns.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                }

                HStack {
                    Text("Trykk på garn for å telle og legge til i '\(selectedLocation)'")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.appSecondaryBackground)

            if availableYarns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.appTertiaryText)
                    Text("Ingen garn funnet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appSecondaryText)

                    Button(action: {
                        showAddNewYarn = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Legg til nytt garn")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.appIconTint)
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(availableYarns) { yarn in
                        Button(action: {
                            yarnToCount = yarn
                            detectedInfoForYarn = nil
                            showQuantityInput = true
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(yarn.brand) \(yarn.type)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.appText)

                                    if !yarn.color.isEmpty {
                                        HStack(spacing: 4) {
                                            Text(yarn.color)
                                            if !yarn.colorNumber.isEmpty {
                                                Text("(\(yarn.colorNumber))")
                                            }
                                        }
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)
                                    }

                                    HStack(spacing: 8) {
                                        Text("\(formatSkeins(yarn.numberOfSkeins)) nøster")
                                        if !yarn.lotNumber.isEmpty {
                                            Text("•")
                                            Text("Parti: \(yarn.lotNumber)")
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.appSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appIconTint)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .padding(.leading)
                    }

                    // Add new yarn button at the end
                    Button(action: {
                        showAddNewYarn = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.appIconTint)
                            Text("Legg til nytt garn")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appIconTint)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.appButtonBackgroundUnselected)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    var countedYarnsSection: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, 8)

            VStack(spacing: 4) {
                HStack {
                    Text("Talt i denne økten (\(countedYarns.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                    Spacer()
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Garn lagt til i '\(selectedLocation)' og merket som sjekket")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }

                HStack {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Trykk X for å angre (fjerner fra lokasjon og tilbakestiller)")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.appSecondaryBackground)

            ForEach(countedYarns) { yarn in
                HStack(spacing: 12) {
                    // Check indicator
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(yarn.brand) \(yarn.type)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appText)

                        if !yarn.color.isEmpty {
                            Text(yarn.color)
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryText)
                        }

                        HStack(spacing: 4) {
                            Text("\(formatSkeins(yarn.numberOfSkeins)) nøster")
                                .font(.system(size: 12))
                                .foregroundColor(.appSecondaryText)
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(.appSecondaryText)
                            Text("Lokasjon: \(yarn.location)")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    Button(action: {
                        removeFromCount(yarn)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()
                    .padding(.leading)
            }
        }
    }

    func addYarnToCount(_ yarn: YarnStashEntry) {
        // Legacy function - redirect to quantity input
        yarnToCount = yarn
        detectedInfoForYarn = nil
        showQuantityInput = true
    }

    func addYarnToCountWithQuantity(_ yarn: YarnStashEntry, quantity: Double, detectedInfo: DetectedYarnInfo?) {
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            // Store original state before modification
            let originalLocation = yarnEntries[index].location
            let originalLastChecked = yarnEntries[index].lastChecked

            // Update barcode if detected from camera (barcode is reliable)
            if let info = detectedInfo, let barcode = info.barcode, !barcode.isEmpty {
                if yarnEntries[index].barcode.isEmpty {
                    yarnEntries[index].barcode = barcode
                } else if yarnEntries[index].barcode != barcode {
                    // Barcode mismatch - ask user
                    scannedBarcode = barcode
                    yarnToUpdateBarcode = yarn
                    showBarcodeUpdateAlert = true
                }
            }

            // Note: Color/lot NOT updated during counting - only barcode is safe
            // OCR color/lot can be inaccurate, only use for adding new yarn

            // Add quantity to existing count
            yarnEntries[index].numberOfSkeins += quantity

            // Modify the yarn
            yarnEntries[index].location = selectedLocation
            yarnEntries[index].lastChecked = Date()
            saveYarnEntries()

            // Add to counted list and store original state if not already counted
            if !countedYarnIds.contains(yarn.id) {
                countedYarnIds.insert(yarn.id)
                originalYarnStates[yarn.id] = (originalLocation, originalLastChecked)
            }

            // Clear search and filters for next yarn
            searchText = ""
            selectedBrand = ""
            selectedType = ""

            // Clear quantity input state
            yarnToCount = nil
            detectedInfoForYarn = nil
        }
    }

    func addNewYarnToCount(_ newYarn: YarnStashEntry) {
        if let index = yarnEntries.firstIndex(where: { $0.id == newYarn.id }) {
            // For new yarn, original state is its current state (which was just set in AddYarnStashView)
            let originalLocation = yarnEntries[index].location
            let originalLastChecked = yarnEntries[index].lastChecked

            // Update with counting session location
            yarnEntries[index].location = selectedLocation
            yarnEntries[index].lastChecked = Date()
            saveYarnEntries()

            // Add to counted list and store original state
            countedYarnIds.insert(newYarn.id)
            originalYarnStates[newYarn.id] = (originalLocation, originalLastChecked)

            // Clear search and filters for next yarn
            searchText = ""
            selectedBrand = ""
            selectedType = ""
        }
        showAddNewYarn = false
    }

    func createNewLocation() {
        let trimmed = newLocationName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        locationManager.addLocation(trimmed)
        selectedLocation = trimmed
        newLocationName = ""
        showNewLocationField = false
    }

    func removeFromCount(_ yarn: YarnStashEntry) {
        countedYarnIds.remove(yarn.id)

        // Restore original state
        if let originalState = originalYarnStates[yarn.id],
           let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries[index].location = originalState.location
            yarnEntries[index].lastChecked = originalState.lastChecked
            saveYarnEntries()
        }

        originalYarnStates.removeValue(forKey: yarn.id)
    }

    func saveYarnEntries() {
        if let encoded = try? JSONEncoder().encode(yarnEntries) {
            UserDefaults.standard.set(encoded, forKey: "savedYarnStash")
        }
    }

    func finishCounting() {
        dismiss()
    }

    func formatSkeins(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", count)
        } else {
            return String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Handle barcode scan result
    func handleBarcodeScanned(_ code: String) {
        // First, try exact barcode match
        if let yarn = availableYarns.first(where: { $0.barcode == code }) {
            addYarnToCount(yarn)
            return
        }

        // If no exact match, store for potential update
        scannedBarcode = code
    }

    // Handle OCR text result with fuzzy matching
    func handleTextRecognized(_ text: String) {
        // Split OCR text into words
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }

        // Score each available yarn by matching words
        var scoredYarns: [(yarn: YarnStashEntry, score: Int)] = []

        for yarn in availableYarns {
            var score = 0
            let yarnWords = [
                yarn.brand,
                yarn.type,
                yarn.color,
                yarn.colorNumber,
                yarn.lotNumber
            ].joined(separator: " ").lowercased()

            for word in words {
                if yarnWords.contains(word) || fuzzyMatch(word, in: yarnWords) {
                    score += 1
                }
            }

            if score > 0 {
                scoredYarns.append((yarn, score))
            }
        }

        // Sort by score descending
        scoredYarns.sort { $0.score > $1.score }

        // If we have a good match (score >= 2), auto-select
        if let bestMatch = scoredYarns.first, bestMatch.score >= 2 {
            addYarnToCount(bestMatch.yarn)
        } else if let firstMatch = scoredYarns.first {
            // Show as potential match in search
            searchText = firstMatch.yarn.brand + " " + firstMatch.yarn.type
        }
    }

    // Simple fuzzy matching - checks if word is within the text with some tolerance
    func fuzzyMatch(_ word: String, in text: String) -> Bool {
        guard word.count >= 3 else { return false }

        // Check for partial match (at least 80% of characters)
        let threshold = Int(Double(word.count) * 0.8)
        var matchCount = 0

        for char in word {
            if text.contains(char) {
                matchCount += 1
            }
        }

        return matchCount >= threshold
    }

    // Update barcode for yarn when counted
    func updateBarcodeIfNeeded(for yarn: YarnStashEntry) {
        // If yarn has no barcode and we scanned one, ask to add it
        if yarn.barcode.isEmpty && !scannedBarcode.isEmpty {
            yarnToUpdateBarcode = yarn
            showBarcodeUpdateAlert = true
        }
        // If yarn has a different barcode, ask to update
        else if !yarn.barcode.isEmpty && !scannedBarcode.isEmpty && yarn.barcode != scannedBarcode {
            yarnToUpdateBarcode = yarn
            showBarcodeUpdateAlert = true
        }
    }

    func confirmBarcodeUpdate() {
        guard let yarn = yarnToUpdateBarcode,
              let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) else { return }

        yarnEntries[index].barcode = scannedBarcode
        saveYarnEntries()

        yarnToUpdateBarcode = nil
        scannedBarcode = ""
    }
}

struct YarnCountingAddView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    let location: String
    let onYarnAdded: (YarnStashEntry, String, Date?) -> Void

    @ObservedObject private var settings = AppSettings.shared

    @State private var selectedBrand: String = ""
    @State private var selectedType: String = ""
    @State private var searchText: String = ""
    @State private var showAddNewYarn: Bool = false

    var availableBrands: [String] {
        Array(Set(yarnEntries.map { $0.brand })).sorted()
    }

    var availableTypes: [String] {
        guard !selectedBrand.isEmpty else { return [] }
        return Array(Set(yarnEntries.filter { $0.brand == selectedBrand }.map { $0.type })).sorted()
    }

    var filteredYarns: [YarnStashEntry] {
        var yarns = yarnEntries

        // Filter by brand
        if !selectedBrand.isEmpty {
            yarns = yarns.filter { $0.brand == selectedBrand }
        }

        // Filter by type
        if !selectedType.isEmpty {
            yarns = yarns.filter { $0.type == selectedType }
        }

        // Filter by search text
        if !searchText.isEmpty {
            yarns = yarns.filter { yarn in
                yarn.color.localizedCaseInsensitiveContains(searchText) ||
                yarn.colorNumber.localizedCaseInsensitiveContains(searchText) ||
                yarn.lotNumber.localizedCaseInsensitiveContains(searchText) ||
                yarn.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        return yarns.sorted { ($0.brand, $0.type, $0.color) < ($1.brand, $1.type, $1.color) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters section
                VStack(spacing: 12) {
                    // Brand filter
                    Picker("Merke", selection: $selectedBrand) {
                        Text("Alle merker").tag("")
                        ForEach(availableBrands, id: \.self) { brand in
                            Text(brand).tag(brand)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedBrand) { _ in
                        selectedType = ""
                    }

                    // Type filter
                    if !selectedBrand.isEmpty && !availableTypes.isEmpty {
                        Picker("Type", selection: $selectedType) {
                            Text("Alle typer").tag("")
                            ForEach(availableTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appSecondaryText)

                        TextField("Søk farge, fargenummer, partinummer...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appSecondaryText)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.appButtonBackgroundUnselected)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    Divider()
                }
                .padding(.top, 12)
                .background(Color.appSecondaryBackground)

                // Results
                if filteredYarns.isEmpty {
                    emptyStateView
                } else {
                    yarnSelectionList
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
            }
            .sheet(isPresented: $showAddNewYarn) {
                AddYarnStashView(
                    yarnEntries: $yarnEntries
                ) { newYarn in
                    // Update the new yarn with location
                    if let index = yarnEntries.firstIndex(where: { $0.id == newYarn.id }) {
                        // For new yarn, original state is empty location and nil timestamp
                        let originalLocation = yarnEntries[index].location
                        let originalLastChecked = yarnEntries[index].lastChecked

                        yarnEntries[index].location = location
                        yarnEntries[index].lastChecked = Date()
                        saveYarnEntries()
                        onYarnAdded(newYarn, originalLocation, originalLastChecked)
                    }
                    showAddNewYarn = false
                    dismiss()
                }
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.appTertiaryText)

            Text("Ingen garn funnet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.appSecondaryText)

            if !selectedBrand.isEmpty || !selectedType.isEmpty || !searchText.isEmpty {
                Text("Prøv å justere filtrene")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
            }

            Button(action: {
                showAddNewYarn = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Legg til nytt garn")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding()
                .background(Color.appIconTint)
                .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground)
    }

    var yarnSelectionList: some View {
        VStack(spacing: 0) {
            // Add new button at top
            Button(action: {
                showAddNewYarn = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.appIconTint)
                    Text("Legg til nytt garn")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appIconTint)
                    Spacer()
                }
                .padding()
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.appSecondaryBackground)

            Divider()

            List {
                ForEach(filteredYarns) { yarn in
                    Button(action: {
                        selectYarn(yarn)
                    }) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(yarn.brand) \(yarn.type)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appText)

                                if !yarn.color.isEmpty {
                                    HStack(spacing: 4) {
                                        Text(yarn.color)
                                        if !yarn.colorNumber.isEmpty {
                                            Text("(\(yarn.colorNumber))")
                                        }
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.appSecondaryText)
                                }

                                HStack(spacing: 8) {
                                    if !yarn.lotNumber.isEmpty {
                                        HStack(spacing: 4) {
                                            Text("Parti:")
                                            Text(yarn.lotNumber)
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(.appSecondaryText)
                                    }

                                    if !yarn.location.isEmpty {
                                        Text("•")
                                            .font(.system(size: 12))
                                            .foregroundColor(.appSecondaryText)

                                        HStack(spacing: 4) {
                                            Image(systemName: "location")
                                                .font(.system(size: 10))
                                            Text(yarn.location)
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(.appSecondaryText)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(formatSkeins(yarn.numberOfSkeins)) nøster")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondaryText)

                                Text(UnitConverter.formatWeight(yarn.totalWeight, unit: settings.currentUnitSystem))
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondaryText)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.appSecondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    func selectYarn(_ yarn: YarnStashEntry) {
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            // Store original state before modification
            let originalLocation = yarnEntries[index].location
            let originalLastChecked = yarnEntries[index].lastChecked

            // Modify the yarn
            yarnEntries[index].location = location
            yarnEntries[index].lastChecked = Date()
            saveYarnEntries()

            // Pass yarn and original state to callback
            onYarnAdded(yarn, originalLocation, originalLastChecked)
        }
        dismiss()
    }

    func saveYarnEntries() {
        if let encoded = try? JSONEncoder().encode(yarnEntries) {
            UserDefaults.standard.set(encoded, forKey: "savedYarnStash")
        }
    }

    func formatSkeins(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", count)
        } else {
            return String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        }
    }
}

#Preview {
    YarnCountingSessionView(yarnEntries: .constant([]))
}
