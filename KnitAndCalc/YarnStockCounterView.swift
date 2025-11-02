//
//  YarnStockCounterView.swift
//  KnitAndCalc
//
//  Yarn stock counter and inventory management
//

import SwiftUI

struct YarnStockCounterView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var yarnEntries: [YarnStashEntry] = []
    @State private var selectedFilter: String = "Alle"
    @State private var showLongestUncheckedAlert: Bool = false
    @State private var showLocationManagement: Bool = false
    @State private var showCountingSession: Bool = false
    @State private var editingYarnId: UUID?

    var filterOptions: [String] {
        var options = ["Alle", "Uten lokasjon"]
        options.append(contentsOf: locationManager.locations)
        return options
    }

    var filteredYarns: [YarnStashEntry] {
        switch selectedFilter {
        case "Alle":
            return yarnEntries
        case "Uten lokasjon":
            return yarnEntries.filter { $0.location.isEmpty }
        default:
            return yarnEntries.filter { $0.location == selectedFilter }
        }
    }

    var groupedFilteredYarns: [(key: String, yarns: [YarnStashEntry])] {
        let grouped = Dictionary(grouping: filteredYarns) { yarn in
            "\(yarn.brand)|\(yarn.type)"
        }
        return grouped.map { (key: $0.key, yarns: $0.value.sorted { $0.color < $1.color }) }
            .sorted { $0.key < $1.key }
    }

    var totalWeightFiltered: Double {
        filteredYarns.reduce(0.0) { sum, yarn in
            sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with filter and actions
            headerSection

            // Stats summary
            if !filteredYarns.isEmpty {
                statsSummarySection
            }

            // Yarn list
            if filteredYarns.isEmpty {
                emptyStateView
            } else {
                yarnListView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showCountingSession = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text(NSLocalizedString("yarn_stock.start_count", comment: ""))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appIconTint)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showLocationManagement = true
                    }) {
                        Label(NSLocalizedString("yarn_stock.manage_locations", comment: ""), systemImage: "folder.badge.gearshape")
                    }

                    Button(action: {
                        showLongestUncheckedAlert = true
                    }) {
                        Label(NSLocalizedString("yarn_stock.show_uncounted", comment: ""), systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.appIconTint)
                }
            }
        }
        .onAppear {
            loadYarnEntries()
            UsageStatisticsManager.shared.recordYarnStockCounterOpen()
        }
        .onChange(of: yarnEntries) { _ in
            saveYarnEntries()
        }
        .onChange(of: showLocationManagement) { isShowing in
            if !isShowing {
                // Reload when location management sheet is dismissed
                loadYarnEntries()
            }
        }
        .sheet(isPresented: $showLongestUncheckedAlert) {
            LongestUncheckedYarnView(yarnEntries: yarnEntries)
        }
        .sheet(isPresented: $showLocationManagement) {
            LocationManagementView()
        }
        .fullScreenCover(isPresented: $showCountingSession) {
            YarnCountingSessionView(yarnEntries: $yarnEntries)
        }
    }

    var headerSection: some View {
        VStack(spacing: 12) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(filterOptions, id: \.self) { option in
                    Text(localizedFilterName(option)).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .padding(.top, 12)

            Divider()
        }
        .background(Color.appSecondaryBackground)
    }

    func localizedFilterName(_ filter: String) -> String {
        switch filter {
        case "Alle":
            return NSLocalizedString("yarn_stock.all", comment: "")
        case "Uten lokasjon":
            return NSLocalizedString("yarn_stock.no_location", comment: "")
        default:
            return filter
        }
    }

    var statsSummarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(filteredYarns.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appIconTint)
                    Text(NSLocalizedString("yarn_stock.yarn", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text(UnitConverter.formatWeight(totalWeightFiltered, unit: settings.currentUnitSystem))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appIconTint)
                    Text(NSLocalizedString("yarn_stock.total_weight", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appButtonBackgroundUnselected)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()
        }
        .background(Color.appSecondaryBackground)
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedFilter == "Uten lokasjon" ? "checkmark.circle" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.appTertiaryText)
            Text(selectedFilter == "Uten lokasjon" ? "Alle garn har lokasjon" : "Ingen garn")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.appSecondaryText)
            if selectedFilter != "Alle" && selectedFilter != "Uten lokasjon" {
                Text("Ingen garn i '\(selectedFilter)'")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground)
    }

    var yarnListView: some View {
        List {
            ForEach(groupedFilteredYarns, id: \.key) { group in
                Section(header: groupHeaderView(for: group)) {
                    ForEach(group.yarns) { yarn in
                        YarnInventoryRowView(
                            yarn: yarn,
                            isEditing: editingYarnId == yarn.id,
                            onLocationChange: { newLocation in
                                updateYarnLocation(yarn, to: newLocation)
                            },
                            onToggleEdit: {
                                if editingYarnId == yarn.id {
                                    editingYarnId = nil
                                } else {
                                    editingYarnId = yarn.id
                                }
                            }
                        )
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    func groupHeaderView(for group: (key: String, yarns: [YarnStashEntry])) -> some View {
        let components = group.key.split(separator: "|")
        let brand = String(components[0])
        let type = String(components[1])
        let totalGrams = group.yarns.reduce(0.0) { sum, yarn in
            sum + (Double(yarn.numberOfSkeins) * yarn.weightPerSkein)
        }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(brand) \(type)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appText)

                Text("\(group.yarns.count) farge\(group.yarns.count == 1 ? "" : "r") • \(UnitConverter.formatWeight(totalGrams, unit: settings.currentUnitSystem))")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)
            }
        }
    }

    func updateYarnLocation(_ yarn: YarnStashEntry, to location: String) {
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries[index].location = location
            editingYarnId = nil
        }
    }

    func checkYarn(_ yarn: YarnStashEntry) {
        if let index = yarnEntries.firstIndex(where: { $0.id == yarn.id }) {
            yarnEntries[index].lastChecked = Date()
        }
    }

    func loadYarnEntries() {
        if let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
           let decoded = try? JSONDecoder().decode([YarnStashEntry].self, from: data) {
            yarnEntries = decoded
        }
    }

    func saveYarnEntries() {
        if let encoded = try? JSONEncoder().encode(yarnEntries) {
            UserDefaults.standard.set(encoded, forKey: "savedYarnStash")
        }
    }
}

struct YarnInventoryRowView: View {
    let yarn: YarnStashEntry
    let isEditing: Bool
    let onLocationChange: (String) -> Void
    let onToggleEdit: () -> Void

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var locationManager = LocationManager.shared

    var locationOptions: [String] {
        var options = ["Ingen lokasjon"]
        options.append(contentsOf: locationManager.locations)
        return options
    }

    var timeSinceLastCheck: String {
        guard let lastChecked = yarn.lastChecked else {
            return "Aldri sjekket"
        }

        let interval = Date().timeIntervalSince(lastChecked)
        let days = Int(interval / 86400)

        if days == 0 {
            return "I dag"
        } else if days == 1 {
            return "1 dag siden"
        } else if days < 7 {
            return "\(days) dager siden"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) uke\(weeks == 1 ? "" : "r") siden"
        } else if days < 365 {
            let months = days / 30
            return "\(months) måned\(months == 1 ? "" : "er") siden"
        } else {
            let years = days / 365
            return "\(years) år siden"
        }
    }

    var statusColor: Color {
        guard let lastChecked = yarn.lastChecked else {
            return .red
        }

        let interval = Date().timeIntervalSince(lastChecked)
        let days = Int(interval / 86400)

        if days < 30 {
            return .green
        } else if days < 90 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Color name
                    HStack(spacing: 8) {
                        if !yarn.color.isEmpty {
                            Text(yarn.color)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appText)

                            if !yarn.colorNumber.isEmpty {
                                Text("(\(yarn.colorNumber))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondaryText)
                            }
                        } else {
                            Text("Ingen farge")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.appSecondaryText)
                        }
                    }

                    // Quantity info
                    HStack(spacing: 8) {
                        Text("\(formatSkeins(yarn.numberOfSkeins)) nøster")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)

                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)

                        Text(UnitConverter.formatWeight(yarn.totalWeight, unit: settings.currentUnitSystem))
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)
                    }

                    // Location and check status
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 11))
                            Text(yarn.location.isEmpty ? "Ingen lokasjon" : yarn.location)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(yarn.location.isEmpty ? .orange : .appSecondaryText)

                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondaryText)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)

                            Text(timeSinceLastCheck)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                    }
                }

                Spacer()

                Button(action: onToggleEdit) {
                    Image(systemName: isEditing ? "xmark.circle" : "location.circle")
                        .font(.system(size: 24))
                        .foregroundColor(isEditing ? .red : .appSecondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
            }

            // Location picker when editing
            if isEditing {
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        Text(NSLocalizedString("yarn_stock.move_to", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appSecondaryText)

                        Spacer()
                    }

                    ForEach(locationOptions, id: \.self) { location in
                        Button(action: {
                            let newLocation = location == "Ingen lokasjon" ? "" : location
                            onLocationChange(newLocation)
                        }) {
                            HStack {
                                Text(location)
                                    .font(.system(size: 15))
                                    .foregroundColor(.appText)

                                Spacer()

                                if (location == "Ingen lokasjon" && yarn.location.isEmpty) ||
                                   (location == yarn.location) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appIconTint)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                (location == "Ingen lokasjon" && yarn.location.isEmpty) ||
                                (location == yarn.location) ?
                                Color.appButtonBackgroundUnselected : Color.clear
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    func formatSkeins(_ count: Double) -> String {
        if count.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", count)
        } else {
            return String(format: "%.1f", count).replacingOccurrences(of: ".", with: ",")
        }
    }
}

struct LongestUncheckedYarnView: View {
    let yarnEntries: [YarnStashEntry]
    @Environment(\.dismiss) var dismiss
    @State private var selectedDays: Int = 30

    let dayOptions = [2, 7, 14, 30, 60, 90, 180]

    var uncountedYarns: [YarnStashEntry] {
        yarnEntries
            .filter { yarn in
                if let lastChecked = yarn.lastChecked {
                    let interval = Date().timeIntervalSince(lastChecked)
                    let days = Int(interval / 86400)
                    return days >= selectedDays
                }
                return true
            }
            .sorted { yarn1, yarn2 in
                let date1 = yarn1.lastChecked ?? Date.distantPast
                let date2 = yarn2.lastChecked ?? Date.distantPast
                return date1 < date2
            }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Days filter picker
                VStack(spacing: 12) {
                    Picker("Days", selection: $selectedDays) {
                        ForEach(dayOptions, id: \.self) { days in
                            Text(String(format: NSLocalizedString("yarn_stock.days_filter", comment: ""), days)).tag(days)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Divider()
                }
                .background(Color.appSecondaryBackground)

                if uncountedYarns.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Alt er oppdatert!")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appText)
                        Text("Alle garn har blitt talt nylig")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(uncountedYarns) { yarn in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(yarn.brand) \(yarn.type)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appText)

                                    if !yarn.color.isEmpty {
                                        Text(yarn.color)
                                            .font(.system(size: 14))
                                            .foregroundColor(.appSecondaryText)
                                    }

                                    if !yarn.location.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location")
                                                .font(.system(size: 12))
                                            Text(yarn.location)
                                        }
                                        .font(.system(size: 13))
                                        .foregroundColor(.appSecondaryText)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    if let lastChecked = yarn.lastChecked {
                                        let interval = Date().timeIntervalSince(lastChecked)
                                        let days = Int(interval / 86400)
                                        Text("\(days) dager")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.red)
                                        Text("siden")
                                            .font(.system(size: 12))
                                            .foregroundColor(.appSecondaryText)
                                    } else {
                                        Text("Aldri")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .navigationTitle(NSLocalizedString("yarn_stock.uncounted_yarn", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lukk") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    YarnStockCounterView()
}
