//
//  EditYarnStashView.swift
//  KnitAndCalc
//
//  Edit yarn stash entry view
//

import SwiftUI

struct EditYarnStashView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var yarnEntries: [YarnStashEntry]
    let yarn: YarnStashEntry
    var projects: Binding<[Project]>? = nil
    @ObservedObject private var settings = AppSettings.shared

    private static var newBrandKey: String { String(localized: "(Nytt merke)") }
    private static var newTypeKey: String { String(localized: "(Ny type)") }

    @State private var selectedBrand: String = ""
    @State private var selectedType: String = ""
    @State private var customBrand: String = ""
    @State private var customType: String = ""
    @State private var showCustomBrandField: Bool = false
    @State private var showCustomTypeField: Bool = false
    @State private var weightPerSkein: String = ""
    @State private var lengthPerSkein: String = ""
    @State private var numberOfSkeins: String = ""
    @State private var color: String = ""
    @State private var colorNumber: String = ""
    @State private var lotNumber: String = ""
    @State private var notes: String = ""
    @State private var selectedGauge: GaugeOption = .none
    @State private var localProjects: [Project] = []
    @State private var projectYarnToUnlink: (project: Project, projectYarn: ProjectYarn)?
    @State private var showEditQuantity: Bool = false
    @State private var editingProject: Project?
    @State private var editingProjectYarn: ProjectYarn?
    @State private var showDeleteAlert: Bool = false

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

    var currentProjects: [Project] {
        projects?.wrappedValue ?? localProjects
    }

    var isFormValid: Bool {
        !finalBrand.isEmpty &&
        !finalType.isEmpty &&
        Double(weightPerSkein) != nil &&
        Double(lengthPerSkein) != nil &&
        Int(numberOfSkeins) != nil
    }

    var linkedProjects: [(project: Project, yarns: [ProjectYarn])] {
        currentProjects.compactMap { project in
            let projectYarns = project.linkedYarns.filter { $0.yarnStashId == yarn.id }
            return projectYarns.isEmpty ? nil : (project, projectYarns)
        }
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
                    }
                }

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

                Section(header: Text("Garninformasjon")) {
                    HStack {
                        Text(settings.currentUnitSystem == .metric ? "Vekt per nøste (g)" : "Vekt per nøste (oz)")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $weightPerSkein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(settings.currentUnitSystem == .metric ? "Lengde per nøste (m)" : "Lengde per nøste (yd)")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $lengthPerSkein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Antall nøster")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $numberOfSkeins)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Farge")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $color)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Fargenummer")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $colorNumber)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Innfarging/Partinummer")
                            .frame(width: 160, alignment: .leading)
                        TextField("", text: $lotNumber)
                            .multilineTextAlignment(.trailing)
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
                }

                Section {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Slett garn")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }

                if !linkedProjects.isEmpty {
                    Section(header: Text("Koblet til prosjekter")) {
                        ForEach(linkedProjects, id: \.project.id) { item in
                            ForEach(item.yarns) { projectYarn in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.project.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.appText)

                                        Text(formatProjectYarnQuantity(projectYarn))
                                            .font(.system(size: 13))
                                            .foregroundColor(.appSecondaryText)
                                    }

                                    Spacer()

                                    HStack(spacing: 16) {
                                        Button(action: {
                                            editingProject = item.project
                                            editingProjectYarn = projectYarn
                                            showEditQuantity = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 18))
                                                .foregroundColor(.appIconTint)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Button(action: {
                                            projectYarnToUnlink = (item.project, projectYarn)
                                        }) {
                                            Image(systemName: "link.badge.minus")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rediger garn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { updateYarn() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .appIconTint : .appTertiaryText)
                }
            }
            .onAppear {
                loadYarnData()
                if projects == nil {
                    loadProjects()
                }
            }
            .alert("Koble fra prosjekt", isPresented: .constant(projectYarnToUnlink != nil), presenting: projectYarnToUnlink) { item in
                Button("Avbryt", role: .cancel) {
                    projectYarnToUnlink = nil
                }
                Button("Koble fra", role: .destructive) {
                    unlinkProjectYarn(project: item.project, projectYarn: item.projectYarn)
                }
            } message: { item in
                Text("Er du sikker på at du vil koble fra dette garnet fra \"\(item.project.name)\"? Prosjektet vil også miste garnet i sin oversikt.")
            }
            .alert("Slett garn", isPresented: $showDeleteAlert) {
                Button("Avbryt", role: .cancel) {
                    showDeleteAlert = false
                }
                Button("Slett", role: .destructive) {
                    deleteYarn()
                }
            } message: {
                if !linkedProjects.isEmpty {
                    Text("Er du sikker på at du vil slette dette garnet? Det er koblet til \(linkedProjects.count) prosjekt\(linkedProjects.count == 1 ? "" : "er") og vil bli fjernet derfra også.")
                } else {
                    Text("Er du sikker på at du vil slette dette garnet?")
                }
            }
            .sheet(isPresented: $showEditQuantity, onDismiss: {
                if projects == nil {
                    saveProjects()
                }
                editingProject = nil
                editingProjectYarn = nil
            }) {
                if let project = editingProject, let projectYarn = editingProjectYarn {
                    EditProjectYarnQuantityView(
                        projects: projects ?? $localProjects,
                        project: project,
                        projectYarn: projectYarn,
                        yarn: yarn
                    )
                }
            }
        }
    }

    func loadYarnData() {
        // Check if current brand exists in the list
        if existingBrands.contains(yarn.brand) {
            selectedBrand = yarn.brand
            showCustomBrandField = false
        } else {
            selectedBrand = Self.newBrandKey
            customBrand = yarn.brand
            showCustomBrandField = true
        }

        // Check if current type exists for this brand
        let typesForBrand = Array(Set(yarnEntries.filter { $0.brand == yarn.brand }.map { $0.type })).sorted()
        if typesForBrand.contains(yarn.type) {
            selectedType = yarn.type
            showCustomTypeField = false
        } else {
            selectedType = Self.newTypeKey
            customType = yarn.type
            showCustomTypeField = true
        }

        weightPerSkein = settings.currentUnitSystem == .imperial ?
            String(format: "%.1f", UnitConverter.gramsToOunces(yarn.weightPerSkein)) :
            String(format: "%.0f", yarn.weightPerSkein)
        lengthPerSkein = settings.currentUnitSystem == .imperial ?
            String(format: "%.0f", UnitConverter.metersToYards(yarn.lengthPerSkein)) :
            String(format: "%.0f", yarn.lengthPerSkein)
        numberOfSkeins = String(yarn.numberOfSkeins)
        color = yarn.color
        colorNumber = yarn.colorNumber
        lotNumber = yarn.lotNumber
        notes = yarn.notes
        selectedGauge = yarn.gauge
    }

    func updateYarn() {
        guard let weight = Double(weightPerSkein),
              let length = Double(lengthPerSkein),
              let count = Int(numberOfSkeins) else {
            return
        }

        // Convert from imperial to metric if needed
        let weightInGrams = settings.currentUnitSystem == .imperial ? UnitConverter.ouncesToGrams(weight) : weight
        let lengthInMeters = settings.currentUnitSystem == .imperial ? UnitConverter.yardsToMeters(length) : length

        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries[index].brand = finalBrand
            yarnEntries[index].type = finalType
            yarnEntries[index].weightPerSkein = weightInGrams
            yarnEntries[index].lengthPerSkein = lengthInMeters
            yarnEntries[index].numberOfSkeins = count
            yarnEntries[index].color = color
            yarnEntries[index].colorNumber = colorNumber
            yarnEntries[index].lotNumber = lotNumber
            yarnEntries[index].notes = notes
            yarnEntries[index].gauge = selectedGauge
        }

        dismiss()
    }

    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            localProjects = decoded
        }
    }

    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(localProjects) {
            UserDefaults.standard.set(encoded, forKey: "savedProjects")
        }
    }

    func formatProjectYarnQuantity(_ projectYarn: ProjectYarn) -> String {
        switch projectYarn.quantityType {
        case .skeins:
            return "\(Int(projectYarn.quantity)) nøster"
        case .meters:
            return UnitConverter.formatLength(projectYarn.quantity, unit: settings.currentUnitSystem)
        case .grams:
            return UnitConverter.formatWeight(projectYarn.quantity, unit: settings.currentUnitSystem)
        }
    }

    func unlinkProjectYarn(project: Project, projectYarn: ProjectYarn) {
        if let projectsBinding = projects {
            // Use provided binding
            if let projectIndex = projectsBinding.wrappedValue.firstIndex(where: { $0.id == project.id }),
               let yarnIndex = projectsBinding.wrappedValue[projectIndex].linkedYarns.firstIndex(where: { $0.id == projectYarn.id }) {
                projectsBinding.wrappedValue[projectIndex].linkedYarns.remove(at: yarnIndex)
            }
        } else {
            // Use local projects
            if let projectIndex = localProjects.firstIndex(where: { $0.id == project.id }),
               let yarnIndex = localProjects[projectIndex].linkedYarns.firstIndex(where: { $0.id == projectYarn.id }) {
                localProjects[projectIndex].linkedYarns.remove(at: yarnIndex)
                saveProjects()
            }
        }
        projectYarnToUnlink = nil
    }

    func deleteYarn() {
        // Remove yarn from all linked projects first
        for (project, projectYarns) in linkedProjects {
            for projectYarn in projectYarns {
                unlinkProjectYarn(project: project, projectYarn: projectYarn)
            }
        }

        // Remove the yarn entry itself
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries.remove(at: index)
        }

        dismiss()
    }
}

struct EditProjectYarnQuantityView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var projects: [Project]
    let project: Project
    let projectYarn: ProjectYarn
    let yarn: YarnStashEntry
    @ObservedObject private var settings = AppSettings.shared

    @State private var quantity: String = ""
    @State private var quantityType: YarnQuantityType = .skeins

    var isFormValid: Bool {
        Double(quantity) != nil && Double(quantity)! > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prosjekt")) {
                    HStack {
                        Text("Navn")
                            .foregroundColor(.appSecondaryText)
                        Spacer()
                        Text(project.name)
                            .font(.system(size: 16, weight: .medium))
                    }
                }

                Section(header: Text("Mengde")) {
                    Picker("Type", selection: $quantityType) {
                        ForEach(YarnQuantityType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Mengde", text: $quantity)
                        .keyboardType(.decimalPad)

                    if let quantityValue = Double(quantity), quantityValue > 0 {
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
                                Text("\(yarn.numberOfSkeins) nøster (\(UnitConverter.formatWeight(Double(yarn.numberOfSkeins) * yarn.weightPerSkein, unit: settings.currentUnitSystem)))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appText)
                            }

                            Divider()
                                .padding(.vertical, 4)

                            Text("Du reserverer")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appSecondaryText)

                            let calculations = calculateConversions(quantityValue)

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
            .navigationTitle("Rediger mengde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { updateProjectYarn() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .appIconTint : .appTertiaryText)
                }
            }
            .onAppear {
                quantity = String(format: "%.0f", projectYarn.quantity)
                quantityType = projectYarn.quantityType
            }
        }
    }

    func calculateConversions(_ quantityValue: Double) -> (skeins: Double, meters: Double, grams: Double, percentage: Double) {
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

    func updateProjectYarn() {
        guard let quantityValue = Double(quantity),
              quantityValue > 0,
              let projectIndex = projects.firstIndex(where: { $0.id == project.id }),
              let yarnIndex = projects[projectIndex].linkedYarns.firstIndex(where: { $0.id == projectYarn.id }) else {
            return
        }

        projects[projectIndex].linkedYarns[yarnIndex].quantity = quantityValue
        projects[projectIndex].linkedYarns[yarnIndex].quantityType = quantityType

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
    EditYarnStashView(
        yarnEntries: .constant([]),
        yarn: YarnStashEntry(
            brand: "Sandnes",
            type: "Alpakka",
            weightPerSkein: 50,
            lengthPerSkein: 120,
            numberOfSkeins: 5,
            color: "1234",
            lotNumber: "123"
        )
    )
}