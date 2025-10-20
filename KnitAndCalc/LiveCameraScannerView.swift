//
//  LiveCameraScannerView.swift
//  KnitAndCalc
//
//  Live camera scanner with real-time yarn matching and OCR field detection
//

import SwiftUI
import VisionKit
import AVFoundation

// EAN Company Prefix Database
struct EANCompanyDatabase {
    static let prefixes: [String: String] = [
        "690": "Sandnes Garn",
        "578": "Viking Garn",
        "700": "Drops",
        "400": "Rauma Garn",
        // Add more as needed
    ]

    static func companyFromEAN(_ ean: String) -> String? {
        guard ean.count >= 3 else { return nil }
        let prefix = String(ean.prefix(3))
        return prefixes[prefix]
    }
}

// Detected field information
struct DetectedYarnField {
    let text: String
    let bounds: CGRect
    let confidence: Float
}

struct DetectedYarnInfo {
    var barcode: String?
    var color: String?
    var lotNumber: String?
    var detectedCompany: String?
    var brandName: String?
    var productName: String?
    var rawTexts: [DetectedYarnField] = []
}

@available(iOS 16.0, *)
struct LiveCameraScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    let availableYarns: [YarnStashEntry]
    let onYarnSelected: (YarnStashEntry, DetectedYarnInfo) -> Void

    @State private var detectedInfo = DetectedYarnInfo()
    @State private var matchedYarns: [YarnStashEntry] = []
    @State private var isScanning = true

    // Best match stability
    @State private var stableBestMatch: YarnStashEntry?
    @State private var bestMatchScore: Int = 0
    @State private var dotsRemaining: Int = 5
    @State private var matchTimer: Timer?

    // Add yarn sheet
    @State private var showAddYarn = false

    var body: some View {
        VStack(spacing: 0) {
            // Compact camera preview (1/3 of screen)
            ZStack(alignment: .topTrailing) {
                DataScannerViewRepresentable(
                    onBarcodeDetected: handleBarcodeDetected,
                    onTextDetected: handleTextDetected
                )
                .frame(height: 250)

                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                }
                .padding()
            }

            // Detected info summary
            if !detectedInfo.rawTexts.isEmpty || detectedInfo.barcode != nil {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let barcode = detectedInfo.barcode {
                            HStack {
                                Text("EAN:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)
                                Text(barcode)
                                    .font(.system(size: 12))
                                if let company = detectedInfo.detectedCompany {
                                    Text("(\(company))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.appIconTint)
                                }
                            }
                        }
                        if let color = detectedInfo.color {
                            HStack {
                                Text("Color:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)
                                Text(color)
                                    .font(.system(size: 12))
                            }
                        }
                        if let lot = detectedInfo.lotNumber {
                            HStack {
                                Text("Lot:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)
                                Text(lot)
                                    .font(.system(size: 12))
                            }
                        }
                        if let brandName = detectedInfo.brandName {
                            HStack {
                                Text("Brand:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)
                                Text(brandName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.appIconTint)
                            }
                        }
                        if let productName = detectedInfo.productName {
                            HStack {
                                Text("Product:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appSecondaryText)
                                Text(productName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.appIconTint)
                                    .lineLimit(1)
                            }
                        }

                        // Countdown dots
                        if stableBestMatch != nil {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(index < dotsRemaining ? Color.appIconTint : Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    Spacer()

                    // Add Yarn button
                    Button(action: {
                        showAddYarn = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            Text("Add Yarn")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.appIconTint)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(Color.appButtonBackgroundUnselected)
            }

            Divider()

            // Live matched yarns list
            if matchedYarns.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.appSecondaryText)
                    Text("Point camera at yarn label")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(matchedYarns.prefix(10)) { yarn in
                            Button(action: {
                                onYarnSelected(yarn, detectedInfo)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(yarn.brand) \(yarn.type)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appText)

                                        if !yarn.color.isEmpty {
                                            Text(yarn.color)
                                                .font(.system(size: 14))
                                                .foregroundColor(.appSecondaryText)
                                        }

                                        HStack(spacing: 8) {
                                            if !yarn.colorNumber.isEmpty {
                                                Text("# \(yarn.colorNumber)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.appSecondaryText)
                                            }
                                            if !yarn.lotNumber.isEmpty {
                                                Text("Lot: \(yarn.lotNumber)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.appSecondaryText)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.appIconTint)
                                }
                                .padding()
                                .background(Color.appSecondaryBackground)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddYarn) {
            AddYarnStashView(yarnEntries: $yarnEntries, detectedInfo: detectedInfo)
        }
        .onDisappear {
            matchTimer?.invalidate()
        }
    }

    func handleBarcodeDetected(_ barcode: String) {
        detectedInfo.barcode = barcode

        // First use local EAN database for instant feedback
        detectedInfo.detectedCompany = EANCompanyDatabase.companyFromEAN(barcode)
        updateMatches()

        // Then lookup via API for accurate company info
        BarcodeLookupService.shared.lookupBarcode(barcode) { cachedInfo in
            if let info = cachedInfo {
                DispatchQueue.main.async {
                    // Update with API data
                    var updatedInfo = self.detectedInfo
                    updatedInfo.detectedCompany = info.companyName
                    updatedInfo.brandName = info.brandName
                    updatedInfo.productName = info.productName
                    self.detectedInfo = updatedInfo

                    // Re-run matching with better data
                    self.updateMatches()
                }
            }
        }
    }

    func handleTextDetected(_ texts: [DetectedYarnField]) {
        detectedInfo.rawTexts = texts
        analyzeDetectedText()
        updateMatches()
    }

    func analyzeDetectedText() {
        // Sort texts by vertical position (top to bottom)
        let sortedTexts = detectedInfo.rawTexts.sorted { $0.bounds.minY < $1.bounds.minY }

        // Look for field labels and their adjacent values
        for (index, field) in sortedTexts.enumerated() {
            let text = field.text.lowercased()

            // Check if this is a label
            if text.contains("farge") || text.contains("color") || text.contains("colour") {
                // Next text or text to the right is likely the color value
                if let colorValue = findAdjacentValue(to: field, in: sortedTexts, after: index) {
                    detectedInfo.color = colorValue
                }
            } else if text.contains("parti") || text.contains("due") || text.contains("lot") || text.contains("dye") {
                // Next text or text to the right is likely the lot number
                if let lotValue = findAdjacentValue(to: field, in: sortedTexts, after: index) {
                    detectedInfo.lotNumber = lotValue
                }
            }
        }

        // If no labels found, use heuristics
        if detectedInfo.color == nil || detectedInfo.lotNumber == nil {
            applyHeuristics(sortedTexts)
        }
    }

    func findAdjacentValue(to field: DetectedYarnField, in texts: [DetectedYarnField], after index: Int) -> String? {
        // Check next item in array
        if index + 1 < texts.count {
            let nextField = texts[index + 1]
            // If it's on roughly the same line (within 20 points vertically)
            if abs(nextField.bounds.minY - field.bounds.minY) < 20 {
                return nextField.text
            }
        }

        // Check for text to the right on the same line
        for otherField in texts {
            if otherField.bounds.minX > field.bounds.maxX &&
               abs(otherField.bounds.minY - field.bounds.minY) < 20 {
                return otherField.text
            }
        }

        return nil
    }

    func applyHeuristics(_ texts: [DetectedYarnField]) {
        for field in texts {
            let text = field.text

            // Skip very short or very long texts
            guard text.count >= 2 && text.count <= 20 else { continue }

            // Color codes are typically 4-6 characters, often alphanumeric
            if text.count >= 4 && text.count <= 6 && detectedInfo.color == nil {
                // Check if it looks like a color code (has numbers)
                if text.rangeOfCharacter(from: .decimalDigits) != nil {
                    detectedInfo.color = text
                }
            }

            // Lot numbers are typically 6-12 characters, often all numeric
            if text.count >= 6 && text.count <= 12 && detectedInfo.lotNumber == nil {
                let numericCount = text.filter { $0.isNumber }.count
                // If mostly numeric
                if numericCount >= text.count - 2 {
                    detectedInfo.lotNumber = text
                }
            }
        }
    }

    func updateMatches() {
        var scored: [(yarn: YarnStashEntry, score: Int)] = []

        for yarn in availableYarns {
            var score = 0

            // Exact barcode match = very high score
            if let barcode = detectedInfo.barcode, !yarn.barcode.isEmpty {
                if yarn.barcode == barcode {
                    score += 100
                }
            }

            // Company match from EAN
            if let company = detectedInfo.detectedCompany {
                if yarn.brand.lowercased().contains(company.lowercased()) ||
                   company.lowercased().contains(yarn.brand.lowercased()) {
                    score += 30
                }
            }

            // Brand name match from API
            if let brandName = detectedInfo.brandName {
                let brandLower = brandName.lowercased()
                if yarn.brand.lowercased().contains(brandLower) ||
                   brandLower.contains(yarn.brand.lowercased()) {
                    score += 25
                }
                if yarn.type.lowercased().contains(brandLower) ||
                   brandLower.contains(yarn.type.lowercased()) {
                    score += 15
                }
            }

            // Product name match from API
            if let productName = detectedInfo.productName {
                let productLower = productName.lowercased()
                if yarn.type.lowercased().contains(productLower) ||
                   productLower.contains(yarn.type.lowercased()) {
                    score += 20
                }
                if yarn.brand.lowercased().contains(productLower) ||
                   productLower.contains(yarn.brand.lowercased()) {
                    score += 10
                }
            }

            // Color match
            if let color = detectedInfo.color {
                if yarn.colorNumber.lowercased() == color.lowercased() {
                    score += 20
                } else if yarn.color.lowercased().contains(color.lowercased()) {
                    score += 10
                }
            }

            // Lot number match
            if let lot = detectedInfo.lotNumber {
                if yarn.lotNumber.lowercased() == lot.lowercased() {
                    score += 15
                }
            }

            // Fuzzy match on raw texts
            for field in detectedInfo.rawTexts {
                let text = field.text.lowercased()
                if yarn.brand.lowercased().contains(text) || text.contains(yarn.brand.lowercased()) {
                    score += 5
                }
                if yarn.type.lowercased().contains(text) || text.contains(yarn.type.lowercased()) {
                    score += 5
                }
            }

            if score > 0 {
                scored.append((yarn, score))
            }
        }

        // Sort by score descending
        scored.sort { $0.score > $1.score }

        // Best match stability logic
        if let topMatch = scored.first {
            // New match with better score - update and reset timer
            if topMatch.score > bestMatchScore {
                stableBestMatch = topMatch.yarn
                bestMatchScore = topMatch.score
                dotsRemaining = 5
                startStabilityTimer()
            } else if topMatch.yarn.id == stableBestMatch?.id {
                // Same best match - reset timer to extend
                dotsRemaining = 5
                startStabilityTimer()
            }
        }

        // Show stable best match at top if exists, otherwise show all matches
        if let stable = stableBestMatch {
            matchedYarns = [stable] + scored.map { $0.yarn }.filter { $0.id != stable.id }
        } else {
            matchedYarns = scored.map { $0.yarn }
        }
    }

    func startStabilityTimer() {
        matchTimer?.invalidate()

        matchTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { _ in
            if dotsRemaining > 0 {
                dotsRemaining -= 1
            } else {
                // Timer expired - clear stable match
                matchTimer?.invalidate()
                stableBestMatch = nil
                bestMatchScore = 0
            }
        }
    }
}

@available(iOS 16.0, *)
struct DataScannerViewRepresentable: UIViewControllerRepresentable {
    let onBarcodeDetected: (String) -> Void
    let onTextDetected: ([DetectedYarnField]) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(), .text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected, onTextDetected: onTextDetected)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeDetected: (String) -> Void
        let onTextDetected: ([DetectedYarnField]) -> Void

        init(onBarcodeDetected: @escaping (String) -> Void, onTextDetected: @escaping ([DetectedYarnField]) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
            self.onTextDetected = onTextDetected
        }

        // Convert RecognizedItem.Bounds to CGRect
        func boundsToRect(_ bounds: RecognizedItem.Bounds) -> CGRect {
            let origin = bounds.topLeft
            let width = bounds.topRight.x - bounds.topLeft.x
            let height = bounds.bottomLeft.y - bounds.topLeft.y
            return CGRect(origin: origin, size: CGSize(width: width, height: height))
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        func processItems(_ items: [RecognizedItem]) {
            var detectedTexts: [DetectedYarnField] = []

            for item in items {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue {
                        onBarcodeDetected(payload)
                    }
                case .text(let text):
                    let field = DetectedYarnField(
                        text: text.transcript,
                        bounds: self.boundsToRect(text.bounds),
                        confidence: 1.0
                    )
                    detectedTexts.append(field)
                @unknown default:
                    break
                }
            }

            if !detectedTexts.isEmpty {
                onTextDetected(detectedTexts)
            }
        }
    }
}
