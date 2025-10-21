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
        calculatedSkeins != nil && (calculatedSkeins ?? 0) >= 0
    }

    var hasChanged: Bool {
        guard let newCount = calculatedSkeins else { return false }
        return abs(newCount - yarn.numberOfSkeins) > 0.001
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

                // Current count display
                VStack(spacing: 6) {
                    Text("Nåværende telling:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSecondaryText)

                    Text("\(formatSkeins(yarn.numberOfSkeins)) nøster")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appText)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(8)
                .padding(.horizontal)

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
                    Text(quantityType == .skeins ? "Ny telling (antall nøster):" : "Ny telling (vekt i gram):")
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

                // Change indicator with arrow notation
                if let skeins = calculatedSkeins, hasChanged {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Text(formatSkeins(yarn.numberOfSkeins))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.appSecondaryText)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14))
                                .foregroundColor(.appIconTint)

                            Text(formatSkeins(skeins))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appIconTint)

                            Text("nøster")
                                .font(.system(size: 14))
                                .foregroundColor(.appSecondaryText)
                        }

                        if quantityType == .grams {
                            Text("(\(formatWeight(yarn.weightPerSkein)) per nøste)")
                                .font(.system(size: 11))
                                .foregroundColor(.appSecondaryText)
                        }

                        let difference = skeins - yarn.numberOfSkeins
                        if abs(difference) > 0.001 {
                            HStack(spacing: 4) {
                                Image(systemName: difference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(difference > 0 ? .green : .orange)
                                Text("\(difference > 0 ? "+" : "")\(formatSkeins(difference)) nøster")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(difference > 0 ? .green : .orange)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else if calculatedSkeins != nil, !hasChanged {
                    Text("Ingen endring")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                        .padding(.vertical, 4)
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
            .navigationTitle("")
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
