//
//  YarnStashListView.swift
//  KnitAndCalc
//
//  Yarn stash management view
//

import SwiftUI

struct YarnStashListView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var yarnEntries: [YarnStashEntry] = []
    @State private var projects: [Project] = []
    @State private var searchText: String = ""
    @State private var showAddYarn: Bool = false
    @State private var yarnToDelete: YarnStashEntry?
    @State private var yarnToEdit: YarnStashEntry?
    @State private var listRefreshID = UUID()
    @State private var expandedGroupKey: String?

    var filteredYarnEntries: [YarnStashEntry] {
        if searchText.isEmpty {
            return yarnEntries
        } else {
            return yarnEntries.filter { yarn in
                yarn.brand.localizedCaseInsensitiveContains(searchText) ||
                yarn.type.localizedCaseInsensitiveContains(searchText) ||
                yarn.color.localizedCaseInsensitiveContains(searchText) ||
                yarn.lotNumber.localizedCaseInsensitiveContains(searchText) ||
                yarn.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var groupedYarnEntries: [(key: String, yarns: [YarnStashEntry])] {
        let grouped = Dictionary(grouping: filteredYarnEntries) { yarn in
            "\(yarn.brand)|\(yarn.type)"
        }
        return grouped.map { (key: $0.key, yarns: $0.value.sorted { $0.color < $1.color }) }
            .sorted { $0.key < $1.key }
    }

    var totalWeight: Double {
        yarnEntries.reduce(0.0) { sum, yarn in
            sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
        }
    }

    var totalLength: Double {
        yarnEntries.reduce(0.0) { sum, yarn in
            sum + yarn.totalLength
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            yarnContentView
        }
        .navigationTitle("Garnlager")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddYarn = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appIconTint)
                }
            }
        }
        .sheet(isPresented: $showAddYarn) {
            AddYarnStashView(yarnEntries: $yarnEntries)
        }
        .sheet(item: $yarnToEdit, onDismiss: {
            loadProjects()
        }) { yarn in
            EditYarnStashView(yarnEntries: $yarnEntries, yarn: yarn)
        }
        .alert("Slett garn", isPresented: .constant(yarnToDelete != nil), presenting: yarnToDelete) { yarn in
            Button("Avbryt", role: .cancel) {
                yarnToDelete = nil
            }
            Button("Slett", role: .destructive) {
                deleteYarn(yarn)
            }
        } message: { yarn in
            Text("Er du sikker på at du vil slette \"\(yarn.brand) \(yarn.type)\"?")
        }
        .onChange(of: yarnEntries) { _ in
            saveYarnEntries()
        }
        .onAppear {
            loadYarnEntries()
            loadProjects()
        }
    }

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appSecondaryText)

            TextField("Søk i garnlager", text: $searchText)
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
        .padding(.vertical, 8)
        .background(Color.appSecondaryBackground)
    }

    var yarnContentView: some View {
        Group {
            if filteredYarnEntries.isEmpty {
                emptyStateView
            } else {
                yarnListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground)
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.appTertiaryText)
            Text(searchText.isEmpty ? "Ingen garn" : "Ingen treff")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.appSecondaryText)
            Text(searchText.isEmpty ? "Trykk + for å legge til" : "Prøv et annet søk")
                .font(.system(size: 14))
                .foregroundColor(.appSecondaryText)
            Spacer()
        }
    }

    var yarnListView: some View {
        List {
            ForEach(groupedYarnEntries, id: \.key) { group in
                Section {
                    Button(action: {
                        withAnimation {
                            if expandedGroupKey == group.key {
                                expandedGroupKey = nil
                            } else {
                                expandedGroupKey = group.key
                            }
                        }
                    }) {
                        HStack(alignment: .top, spacing: 12) {
                            let firstYarn = group.yarns.first!
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(firstYarn.brand) \(firstYarn.type)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.appText)
                                    .lineLimit(2)
                                    .frame(maxWidth: 280, alignment: .leading)

                                HStack(spacing: 8) {
                                    let entryCount = group.yarns.count
                                    let totalGrams = group.yarns.reduce(0.0) { sum, yarn in
                                        sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
                                    }

                                    Text("\(entryCount) \(entryCount == 1 ? "farge" : "farger")")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)

                                    Text("•")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)

                                    Text(UnitConverter.formatWeight(totalGrams, unit: settings.currentUnitSystem))
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)
                                }
                            }

                            Spacer(minLength: 8)

                            Image(systemName: expandedGroupKey == group.key ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.appSecondaryText)
                                .padding(.top, 2)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.appTertiaryBackground)

                    if expandedGroupKey == group.key {
                        let maxColorWidth = calculateMaxColorWidth(for: group.yarns)
                        ForEach(group.yarns) { yarn in
                            NavigationLink(destination: YarnStashDetailView(
                                yarn: yarn,
                                yarnEntries: $yarnEntries,
                                projects: Binding(
                                    get: { projects },
                                    set: { projects = $0; saveProjects(); listRefreshID = UUID() }
                                )
                            )) {
                                YarnColorRowView(
                                    yarn: yarn,
                                    reservedPercentage: calculateReservedPercentage(for: yarn),
                                    maxColorWidth: maxColorWidth
                                )
                            }
                            .id("\(yarn.id)-\(listRefreshID)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    yarnToDelete = yarn
                                } label: {
                                    Label("Slett", systemImage: "trash")
                                }

                                Button {
                                    yarnToEdit = yarn
                                } label: {
                                    Label("Rediger", systemImage: "pencil")
                                }
                                .tint(Color(red: 0.70, green: 0.65, blue: 0.82))
                            }
                        }
                    }
                }
            }

            if !yarnEntries.isEmpty {
                Section {
                    YarnStashSummaryView(totalWeight: totalWeight, totalLength: totalLength)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }

    func deleteYarn(_ yarn: YarnStashEntry) {
        yarnEntries.removeAll { $0.id == yarn.id }
        yarnToDelete = nil
        saveYarnEntries()
    }

    func loadYarnEntries() {
        if let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
           let decoded = try? JSONDecoder().decode([YarnStashEntry].self, from: data) {
            yarnEntries = decoded
        }
    }

    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }

    func saveYarnEntries() {
        if let encoded = try? JSONEncoder().encode(yarnEntries) {
            UserDefaults.standard.set(encoded, forKey: "savedYarnStash")
        }
    }

    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "savedProjects")
        }
    }

    func calculateMaxColorWidth(for yarns: [YarnStashEntry]) -> CGFloat {
        var maxWidth: CGFloat = 0
        for yarn in yarns {
            let colorText = if !yarn.color.isEmpty && !yarn.colorNumber.isEmpty {
                "\(yarn.color) (\(yarn.colorNumber))"
            } else if !yarn.color.isEmpty {
                yarn.color
            } else {
                ""
            }

            // Estimate width (rough approximation: 12 points per character)
            let estimatedWidth = CGFloat(colorText.count) * 12
            maxWidth = max(maxWidth, estimatedWidth)
        }
        return max(maxWidth, 120) // Minimum 120 pixels for color text
    }

    func calculateReservedPercentage(for yarn: YarnStashEntry) -> Double {
        // Calculate total reserved in grams across all projects
        var totalReservedGrams: Double = 0.0

        for project in projects {
            for linkedYarn in project.linkedYarns {
                if linkedYarn.yarnStashId == yarn.id {
                    switch linkedYarn.quantityType {
                    case .grams:
                        totalReservedGrams += linkedYarn.quantity
                    case .skeins:
                        totalReservedGrams += linkedYarn.quantity * yarn.weightPerSkein
                    case .meters:
                        let gramsPerMeter = yarn.weightPerSkein / yarn.lengthPerSkein
                        totalReservedGrams += linkedYarn.quantity * gramsPerMeter
                    }
                }
            }
        }

        let totalAvailableGrams = Double(yarn.numberOfSkeins) * yarn.weightPerSkein
        if totalAvailableGrams == 0 {
            return 0
        }

        return (totalReservedGrams / totalAvailableGrams) * 100
    }
}

struct YarnColorRowView: View {
    let yarn: YarnStashEntry
    let reservedPercentage: Double
    let maxColorWidth: CGFloat
    @ObservedObject private var settings = AppSettings.shared

    var totalGrams: Double {
        Double(yarn.numberOfSkeins) * yarn.weightPerSkein
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if !yarn.color.isEmpty {
                        Group {
                            if !yarn.colorNumber.isEmpty {
                                Text("\(yarn.color) (\(yarn.colorNumber))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appText)
                                    .lineLimit(2)
                            } else {
                                Text(yarn.color)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appText)
                                    .lineLimit(2)
                            }
                        }
                        .frame(minWidth: min(maxColorWidth, 175), alignment: .leading)

                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)
                    }

                    Text("\(yarn.numberOfSkeins) \(String(localized: "nøster"))")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)

                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)

                    Text(UnitConverter.formatLength(yarn.totalLength, unit: settings.currentUnitSystem))
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)

                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)

                    Text(UnitConverter.formatWeight(totalGrams, unit: settings.currentUnitSystem))
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if reservedPercentage > 0 {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(reservedPercentage))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(reservedPercentage > 100 ? .red : .appSecondary)

                    Text("reservert")
                        .font(.system(size: 8))
                        .foregroundColor(.appSecondaryText)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Models

struct YarnStashEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var brand: String
    var type: String
    var weightPerSkein: Double
    var lengthPerSkein: Double
    var numberOfSkeins: Int
    var color: String
    var colorNumber: String
    var lotNumber: String
    var notes: String
    var gauge: GaugeOption
    var usedSkeins: [UsedSkein]
    var dateCreated: Date

    init(id: UUID = UUID(), brand: String, type: String, weightPerSkein: Double, lengthPerSkein: Double, numberOfSkeins: Int, color: String = "", colorNumber: String = "", lotNumber: String, notes: String = "", gauge: GaugeOption = .none, usedSkeins: [UsedSkein] = [], dateCreated: Date = Date()) {
        self.id = id
        self.brand = brand
        self.type = type
        self.weightPerSkein = weightPerSkein
        self.lengthPerSkein = lengthPerSkein
        self.numberOfSkeins = numberOfSkeins
        self.color = color
        self.colorNumber = colorNumber
        self.lotNumber = lotNumber
        self.notes = notes
        self.gauge = gauge
        self.usedSkeins = usedSkeins
        self.dateCreated = dateCreated
    }

    var totalLength: Double {
        Double(numberOfSkeins) * lengthPerSkein
    }

    var remainingSkeins: Int {
        let usedWeight = usedSkeins.reduce(0.0) { $0 + $1.grams }
        let usedInSkeins = usedWeight / weightPerSkein
        return max(0, numberOfSkeins - Int(ceil(usedInSkeins)))
    }

    var remainingLength: Double {
        let usedWeight = usedSkeins.reduce(0.0) { $0 + $1.grams }
        let lengthPerGram = lengthPerSkein / weightPerSkein
        let usedLength = usedWeight * lengthPerGram
        return max(0, totalLength - usedLength)
    }
}

struct UsedSkein: Identifiable, Codable, Equatable {
    var id: UUID
    var grams: Double
    var date: Date

    init(id: UUID = UUID(), grams: Double, date: Date = Date()) {
        self.id = id
        self.grams = grams
        self.date = date
    }
}

enum GaugeOption: String, Codable, CaseIterable {
    case none = "ingen"
    case gauge8 = "8/10"
    case gauge10 = "10/10"
    case gauge12 = "12/10"
    case gauge14 = "14/10"
    case gauge16 = "16/10"
    case gauge18 = "18/10"
    case gauge20 = "20/10"
    case gauge22 = "22/10"
    case gauge24 = "24/10"
    case gauge26 = "26/10"
    case gauge28 = "28/10"
    case gauge30 = "30/10"
    case gauge32 = "32/10"
    case gauge34 = "34/10"
    case gauge36 = "36/10"
    case gauge38 = "38/10"
    case gauge40 = "40/10"
    case other = "annet"

    var displayName: LocalizedStringKey {
        switch self {
        case .none: return "Ingen"
        case .other: return "Annet"
        default: return LocalizedStringKey(self.rawValue)
        }
    }
}

struct YarnStashSummaryView: View {
    let totalWeight: Double
    let totalLength: Double
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Totalt på lager")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)

                    Text("For morro skyld")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()
            }
            .padding(.horizontal)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(settings.currentUnitSystem == .metric ? "\(Int(totalWeight))" : String(format: "%.1f", UnitConverter.gramsToOunces(totalWeight)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appIconTint)

                    Text(settings.currentUnitSystem == .metric ? "gram totalt" : "oz totalt")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text(settings.currentUnitSystem == .metric ? "\(Int(totalLength))" : String(format: "%.0f", UnitConverter.metersToYards(totalLength)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appIconTint)

                    Text(settings.currentUnitSystem == .metric ? "meter totalt" : "yards totalt")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.appSecondaryBackground)
    }
}

#Preview {
    YarnStashListView()
}