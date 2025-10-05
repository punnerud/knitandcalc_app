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

    @State private var showAddUsedYarn: Bool = false
    @State private var showEditYarn: Bool = false
    @State private var usedGrams: String = ""
    @State private var usedSkeinToDelete: UsedSkein?
    @State private var refreshID = UUID()

    var currentYarn: YarnStashEntry? {
        yarnEntries.first { $0.id == yarn.id }
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
                usedYarnSection
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
        .sheet(isPresented: $showAddUsedYarn) {
            AddUsedYarnView(yarnEntries: $yarnEntries, yarnId: yarn.id)
        }
        .sheet(isPresented: $showEditYarn, onDismiss: {
            refreshID = UUID()
        }) {
            EditYarnStashView(yarnEntries: $yarnEntries, yarn: yarn, projects: $projects)
        }
        .alert("Slett brukt garn", isPresented: .constant(usedSkeinToDelete != nil), presenting: usedSkeinToDelete) { used in
            Button("Avbryt", role: .cancel) {
                usedSkeinToDelete = nil
            }
            Button("Slett", role: .destructive) {
                deleteUsedSkein(used)
            }
        } message: { used in
            Text(String(format: NSLocalizedString("Er du sikker på at du vil slette denne brukt garn-registreringen (%@ g)?", comment: ""), formatNorwegian(used.grams)))
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
                InfoRow(label: NSLocalizedString("Antall nøster", comment: ""), value: "\(currentYarn?.numberOfSkeins ?? yarn.numberOfSkeins)")
                if !(currentYarn?.lotNumber ?? yarn.lotNumber).isEmpty {
                    InfoRow(label: NSLocalizedString("Innfarging/Partinummer", comment: ""), value: currentYarn?.lotNumber ?? yarn.lotNumber)
                }
                InfoRow(label: NSLocalizedString("Strikkefasthet", comment: ""), value: (currentYarn?.gauge ?? yarn.gauge).displayName)
            }
            .padding()
            .background(Color.white)
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
                InfoRow(label: NSLocalizedString("Total lengde", comment: ""), value: UnitConverter.formatLength(currentYarn?.totalLength ?? yarn.totalLength, unit: settings.currentUnitSystem))
                InfoRow(label: NSLocalizedString("Gjenværende nøster", comment: ""), value: "\(currentYarn?.remainingSkeins ?? yarn.remainingSkeins)")
                InfoRow(label: NSLocalizedString("Gjenværende lengde", comment: ""), value: UnitConverter.formatLength(currentYarn?.remainingLength ?? yarn.remainingLength, unit: settings.currentUnitSystem))
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
                .background(Color.white)
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
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }

    var usedYarnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Brukt garn", comment: ""))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appText)

                Spacer()

                Button(action: { showAddUsedYarn = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appIconTint)
                }
            }
            .padding(.horizontal)

            if let usedSkeins = currentYarn?.usedSkeins, !usedSkeins.isEmpty {
                VStack(spacing: 8) {
                    ForEach(usedSkeins) { used in
                        UsedYarnRow(
                            used: used,
                            lengthPerGram: (currentYarn?.lengthPerSkein ?? yarn.lengthPerSkein) / (currentYarn?.weightPerSkein ?? yarn.weightPerSkein),
                            onDelete: { usedSkeinToDelete = used },
                            unitSystem: settings.currentUnitSystem
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text(NSLocalizedString("Ingen brukt garn registrert", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }

    func deleteUsedSkein(_ used: UsedSkein) {
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries[index].usedSkeins.removeAll { $0.id == used.id }
        }
        usedSkeinToDelete = nil
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

struct UsedYarnRow: View {
    let used: UsedSkein
    let lengthPerGram: Double
    let onDelete: () -> Void
    let unitSystem: UnitSystem

    var calculatedLength: Double {
        used.grams * lengthPerGram
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(UnitConverter.formatWeight(used.grams, unit: unitSystem))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appText)

                Text(String(format: NSLocalizedString("Ca. %@", comment: ""), UnitConverter.formatLength(calculatedLength, unit: unitSystem)))
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)
            }

            Spacer()

            Text(used.date, style: .date)
                .font(.system(size: 13))
                .foregroundColor(.appSecondaryText)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
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

struct AddUsedYarnView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    let yarnId: UUID

    @State private var grams: String = ""

    var isFormValid: Bool {
        Double(grams) != nil && Double(grams)! > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Brukt garn")) {
                    TextField("Gram", text: $grams)
                        .keyboardType(.decimalPad)

                    if let gramsValue = Double(grams),
                       gramsValue > 0,
                       let yarn = yarnEntries.first(where: { $0.id == yarnId }) {
                        let lengthPerGram = yarn.lengthPerSkein / yarn.weightPerSkein
                        let calculatedLength = gramsValue * lengthPerGram

                        HStack {
                            Text(NSLocalizedString("Ca. lengde", comment: ""))
                                .foregroundColor(.appSecondaryText)
                            Spacer()
                            Text(String(format: "%@ m", formatNorwegian(calculatedLength)))
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                }
            }
            .navigationTitle("Legg til brukt garn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { addUsedYarn() }) {
                        Text(NSLocalizedString("Lagre", comment: ""))
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .appIconTint : .appTertiaryText)
                }
            }
        }
    }

    func addUsedYarn() {
        guard let gramsValue = Double(grams), gramsValue > 0 else {
            return
        }

        if let index = yarnEntries.firstIndex(where: { $0.id == yarnId }) {
            let usedSkein = UsedSkein(grams: gramsValue)
            yarnEntries[index].usedSkeins.append(usedSkein)
        }

        dismiss()
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
            numberOfSkeins: 5,
            color: "1234",
            lotNumber: "123",
            notes: "Nydelig garn til jakker"
        ),
        yarnEntries: .constant([]),
        projects: .constant([])
    )
}