//
//  YarnQuantityInputView.swift
//  KnitAndCalc
//
//  Input quantity when counting yarn (skeins or grams)
//

import SwiftUI

struct YarnQuantityInputView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = AppSettings.shared

    let yarn: YarnStashEntry
    let detectedInfo: DetectedYarnInfo?
    let onConfirm: (Double) -> Void

    @State private var quantityText: String = ""
    @State private var quantityType: QuantityType = .skeins
    @FocusState private var isFieldFocused: Bool

    enum QuantityType: String, CaseIterable {
        case skeins = "Nøster"
        case grams = "Gram"
    }

    var calculatedSkeins: Double? {
        guard let quantity = Double(quantityText.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }

        switch quantityType {
        case .skeins:
            return quantity
        case .grams:
            return quantity / yarn.weightPerSkein
        }
    }

    var isValid: Bool {
        calculatedSkeins != nil && (calculatedSkeins ?? 0) > 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Yarn info
                VStack(spacing: 4) {
                    Text("\(yarn.brand) \(yarn.type)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)

                    if !yarn.color.isEmpty {
                        Text(yarn.color)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                    }

                    HStack(spacing: 12) {
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
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.appSecondaryBackground)
                .cornerRadius(8)

                // Quantity type selector
                Picker("Type", selection: $quantityType) {
                    ForEach(QuantityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Quantity input
                VStack(alignment: .center, spacing: 4) {
                    Text(quantityType == .skeins ? "Antall nøster:" : "Vekt i gram:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSecondaryText)

                    TextField("", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .focused($isFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Ferdig") {
                                    isFieldFocused = false
                                }
                                .foregroundColor(.appIconTint)
                            }
                        }
                }
                .padding(.horizontal)

                // Conversion info
                if let skeins = calculatedSkeins {
                    VStack(spacing: 2) {
                        if quantityType == .grams {
                            Text("= \(formatSkeins(skeins)) nøster")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appIconTint)
                        }

                        Text("(\(formatWeight(yarn.weightPerSkein)) per nøste)")
                            .font(.system(size: 11))
                            .foregroundColor(.appSecondaryText)
                    }
                }

                Spacer()

                // Confirm button
                Button(action: {
                    if let skeins = calculatedSkeins {
                        onConfirm(skeins)
                        dismiss()
                    }
                }) {
                    Text("Legg til")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.appIconTint : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 12)
            .navigationTitle(detectedInfo != nil ? yarn.brand : "Antall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFieldFocused = true
            }
        }
    }

    func formatSkeins(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", count)
        } else {
            return String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        }
    }

    func formatWeight(_ weight: Double) -> String {
        let displayWeight = settings.currentUnitSystem == .imperial ?
            UnitConverter.gramsToOunces(weight) : weight
        let unit = settings.currentUnitSystem == .imperial ? "oz" : "g"

        if displayWeight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f%@", displayWeight, unit)
        } else {
            return String(format: "%.1f%@", displayWeight, unit)
        }
    }
}
