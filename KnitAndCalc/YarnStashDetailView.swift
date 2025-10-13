//
//  YarnStashDetailView.swift
//  KnitAndCalc
//
//  Yarn stash detail view with used yarn tracking
//

import SwiftUI

struct YarnStashDetailView: View {
    let yarn: YarnStashEntry
    @Binding var yarnEntries: [YarnStashEntry]
    @Binding var projects: [Project]
    @ObservedObject private var settings = AppSettings.shared

    @State private var showEditYarn: Bool = false
    @State private var refreshID = UUID()
    @State private var showDeleteConfirmation: Bool = false
    @State private var hasModifiedSkeins: Bool = false
    @State private var showRoundButton: Bool = false
    @State private var showRoundConfirmation: Bool = false
    @Environment(\.dismiss) var dismiss

    var currentYarn: YarnStashEntry? {
        yarnEntries.first { $0.id == yarn.id }
    }

    func formatSkeins(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", count)
        } else {
            return String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        }
    }

    var linkedProjects: [(project: Project, yarns: [ProjectYarn])] {
        projects.compactMap { project in
            let projectYarns = project.linkedYarns.filter { $0.yarnStashId == yarn.id }
            return projectYarns.isEmpty ? nil : (project, projectYarns)
        }
    }

    var totalReservedGrams: Double {
        var total: Double = 0.0
        for project in projects {
            for linkedYarn in project.linkedYarns {
                if linkedYarn.yarnStashId == yarn.id {
                    switch linkedYarn.quantityType {
                    case .grams:
                        total += linkedYarn.quantity
                    case .skeins:
                        total += linkedYarn.quantity * yarn.weightPerSkein
                    case .meters:
                        let gramsPerMeter = yarn.weightPerSkein / yarn.lengthPerSkein
                        total += linkedYarn.quantity * gramsPerMeter
                    }
                }
            }
        }
        return total
    }

    var reservedPercentage: Double {
        let totalAvailableGrams = Double(yarn.numberOfSkeins) * yarn.weightPerSkein
        if totalAvailableGrams == 0 {
            return 0
        }
        return (totalReservedGrams / totalAvailableGrams) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicInfoSection
                summarySection
                reservedSection
                notesSection
                deleteSection
            }
            .padding(.vertical)
        }
        .background(Color.appSecondaryBackground)
        .navigationTitle("\(yarn.brand) \(yarn.type)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditYarn = true }) {
                    Text(NSLocalizedString("Rediger", comment: ""))
                        .font(.system(size: 17))
                        .foregroundColor(.appIconTint)
                }
            }
        }
        .sheet(isPresented: $showEditYarn, onDismiss: {
            refreshID = UUID()
        }) {
            EditYarnStashView(yarnEntries: $yarnEntries, yarn: yarn, projects: $projects)
        }
        .alert("Slett garn", isPresented: $showDeleteConfirmation) {
            Button("Avbryt", role: .cancel) {}
            Button("Slett", role: .destructive) {
                deleteYarn()
            }
        } message: {
            Text("Er du sikker på at du vil slette \"\(yarn.brand) \(yarn.type)\"?\n\nTips: Du kan også trekke til venstre på oversikten for å redigere eller slette. Det er raskere enn å bruke denne knappen.")
        }
        .alert("Avrund antall nøster", isPresented: $showRoundConfirmation) {
            Button("Avbryt", role: .cancel) {}
            Button("Avrund", role: .destructive) {
                roundToWhole()
            }
        } message: {
            let currentValue = currentYarn?.numberOfSkeins ?? yarn.numberOfSkeins
            let roundedValue = round(currentValue)
            Text("Vil du avrunde fra \(formatSkeins(currentValue)) til \(formatSkeins(roundedValue)) nøster?\n\nDu kan alltid endre dette igjen under \"Rediger\".")
        }
    }

    var deleteSection: some View {
        VStack {
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Spacer()
                    Text("Slett garn")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            .padding()
            .background(Color.appBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    func deleteYarn() {
        yarnEntries.removeAll { $0.id == yarn.id }
        dismiss()
    }

    var skeinAdjusterRow: some View {
        HStack {
            Text(NSLocalizedString("Antall nøster", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryText)

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    adjustSkeins(by: -1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appIconTint)
                }
                .buttonStyle(PlainButtonStyle())

                VStack(spacing: 4) {
                    Text(formatSkeins(currentYarn?.numberOfSkeins ?? yarn.numberOfSkeins))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appText)

                    if showRoundButton {
                        Button(action: {
                            showRoundConfirmation = true
                        }) {
                            let currentValue = currentYarn?.numberOfSkeins ?? yarn.numberOfSkeins
                            let roundedValue = round(currentValue)
                            Text("\(formatSkeins(currentValue)) => \(formatSkeins(roundedValue))")
                                .font(.system(size: 11))
                                .foregroundColor(.appIconTint)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(minWidth: 50)

                Button(action: {
                    adjustSkeins(by: 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appIconTint)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    func adjustSkeins(by amount: Int) {
        guard let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) else { return }
        let newValue = max(0, yarnEntries[index].numberOfSkeins + Double(amount))
        yarnEntries[index].numberOfSkeins = newValue
        hasModifiedSkeins = true

        // Show round button if there's a decimal part after modification
        let hasDecimal = newValue.truncatingRemainder(dividingBy: 1) != 0
        withAnimation {
            showRoundButton = hasDecimal && hasModifiedSkeins
        }
    }

    func roundToWhole() {
        guard let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) else { return }
        yarnEntries[index].numberOfSkeins = round(yarnEntries[index].numberOfSkeins)
        withAnimation {
            showRoundButton = false
        }
    }

    var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Garninformasjon", comment: ""))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.appText)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if !(currentYarn?.color ?? yarn.color).isEmpty {
                    InfoRow(label: NSLocalizedString("Farge", comment: ""), value: currentYarn?.color ?? yarn.color)
                }
                if !(currentYarn?.colorNumber ?? yarn.colorNumber).isEmpty {
                    InfoRow(label: NSLocalizedString("Fargenummer", comment: ""), value: currentYarn?.colorNumber ?? yarn.colorNumber)
                }
                InfoRow(label: NSLocalizedString("Vekt per nøste", comment: ""), value: UnitConverter.formatWeight(currentYarn?.weightPerSkein ?? yarn.weightPerSkein, unit: settings.currentUnitSystem))
                InfoRow(label: NSLocalizedString("Lengde per nøste", comment: ""), value: UnitConverter.formatLength(currentYarn?.lengthPerSkein ?? yarn.lengthPerSkein, unit: settings.currentUnitSystem))

                skeinAdjusterRow

                if !(currentYarn?.lotNumber ?? yarn.lotNumber).isEmpty {
                    InfoRow(label: NSLocalizedString("Innfarging/Partinummer", comment: ""), value: currentYarn?.lotNumber ?? yarn.lotNumber)
                }
                InfoRow(label: NSLocalizedString("Strikkefasthet", comment: ""), value: (currentYarn?.gauge ?? yarn.gauge).displayName)
            }
            .padding()
            .background(Color.appBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Oversikt", comment: ""))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.appText)
                .padding(.horizontal)

            VStack(spacing: 12) {
                InfoRow(label: NSLocalizedString("Total vekt", comment: ""), value: UnitConverter.formatWeight(currentYarn?.totalWeight ?? yarn.totalWeight, unit: settings.currentUnitSystem))
                InfoRow(label: NSLocalizedString("Total lengde", comment: ""), value: UnitConverter.formatLength(currentYarn?.totalLength ?? yarn.totalLength, unit: settings.currentUnitSystem))
            }
            .padding()
            .background(Color.appButtonBackgroundUnselected)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var reservedSection: some View {
        if !linkedProjects.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("Reservert til prosjekter", comment: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appText)

                    Spacer()

                    Text("\(Int(reservedPercentage))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(reservedPercentage > 100 ? .red : .appIconTint)
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(linkedProjects, id: \.project.id) { item in
                        ProjectYarnRow(
                            project: item.project,
                            linkedYarns: item.yarns,
                            yarn: yarn
                        )
                    }
                }
                .padding()
                .background(Color.appBackground)
                .cornerRadius(12)
                .padding(.horizontal)

                HStack {
                    Text(NSLocalizedString("Totalt reservert:", comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appSecondaryText)

                    Spacer()

                    Text(UnitConverter.formatWeight(totalReservedGrams, unit: settings.currentUnitSystem))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appText)
                }
                .padding(.horizontal)
            }
            .id(refreshID)
        }
    }

    @ViewBuilder
    var notesSection: some View {
        if let notes = currentYarn?.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Notater", comment: ""))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appText)
                    .padding(.horizontal)

                Text(notes)
                    .font(.system(size: 15))
                    .foregroundColor(.appText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }


    func formatNorwegian(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    private var localizedValue: LocalizedStringKey?

    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.localizedValue = nil
    }

    init(label: String, value: LocalizedStringKey) {
        self.label = label
        self.value = ""
        self.localizedValue = value
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryText)

            Spacer()

            if let localizedValue = localizedValue {
                Text(localizedValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appText)
            } else {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appText)
            }
        }
    }
}

struct ProjectYarnRow: View {
    let project: Project
    let linkedYarns: [ProjectYarn]
    let yarn: YarnStashEntry
    @ObservedObject private var settings = AppSettings.shared

    var totalQuantityText: String {
        var quantities: [String] = []

        for linkedYarn in linkedYarns {
            let quantityStr: String
            switch linkedYarn.quantityType {
            case .skeins:
                quantityStr = "\(Int(linkedYarn.quantity)) nøster"
            case .meters:
                quantityStr = UnitConverter.formatLength(linkedYarn.quantity, unit: settings.currentUnitSystem)
            case .grams:
                quantityStr = UnitConverter.formatWeight(linkedYarn.quantity, unit: settings.currentUnitSystem)
            }
            quantities.append(quantityStr)
        }

        return quantities.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(project.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appText)

            HStack(spacing: 8) {
                Image(systemName: project.status.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)

                Text(project.status.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)

                Text("•")
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)

                Text(totalQuantityText)
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    YarnStashDetailView(
        yarn: YarnStashEntry(
            brand: "Sandnes",
            type: "Alpakka",
            weightPerSkein: 50,
            lengthPerSkein: 120,
            numberOfSkeins: 5.0,
            color: "1234",
            lotNumber: "123",
            notes: "Nydelig garn til jakker"
        ),
        yarnEntries: .constant([]),
        projects: .constant([])
    )
}