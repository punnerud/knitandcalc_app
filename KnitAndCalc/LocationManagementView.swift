//
//  LocationManagementView.swift
//  KnitAndCalc
//
//  Manage yarn storage locations
//

import SwiftUI

struct LocationManagementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var newLocationName: String = ""
    @State private var editingLocation: String?
    @State private var editedName: String = ""
    @State private var locationToDelete: String?
    @State private var yarnEntries: [YarnStashEntry] = []
    @FocusState private var focusedField: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Add new location section
                VStack(spacing: 12) {
                    HStack {
                        TextField("Ny lokasjon", text: $newLocationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField)

                        Button(action: addLocation) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(newLocationName.isEmpty ? .gray : .appIconTint)
                        }
                        .disabled(newLocationName.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Divider()
                }
                .background(Color.appSecondaryBackground)

                // Locations list
                if locationManager.locations.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.appTertiaryText)
                        Text("Ingen lokasjoner")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.appSecondaryText)
                        Text("Legg til en lokasjon over")
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryText)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appSecondaryBackground)
                } else {
                    List {
                        ForEach(locationManager.locations, id: \.self) { location in
                            if editingLocation == location {
                                HStack {
                                    TextField("Lokasjonsnavn", text: $editedName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())

                                    Button(action: {
                                        saveEditedLocation(oldName: location)
                                    }) {
                                        Text("Lagre")
                                            .foregroundColor(.appIconTint)
                                    }
                                    .disabled(editedName.isEmpty)

                                    Button(action: {
                                        editingLocation = nil
                                        editedName = ""
                                    }) {
                                        Text("Avbryt")
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.appText)

                                        let count = yarnCountForLocation(location)
                                        Text("\(count) garn")
                                            .font(.system(size: 13))
                                            .foregroundColor(.appSecondaryText)
                                    }

                                    Spacer()

                                    Button(action: {
                                        editingLocation = location
                                        editedName = location
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.appIconTint)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        locationToDelete = location
                                    } label: {
                                        Label("Slett", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Lokasjoner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ferdig") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadYarnEntries()
            }
            .alert("Slett lokasjon", isPresented: .constant(locationToDelete != nil), presenting: locationToDelete) { location in
                Button("Avbryt", role: .cancel) {
                    locationToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    deleteLocation(location)
                }
            } message: { location in
                let count = yarnCountForLocation(location)
                if count > 0 {
                    Text("Er du sikker på at du vil slette '\(location)'? \(count) garn bruker denne lokasjonen og vil bli satt til ingen lokasjon.")
                } else {
                    Text("Er du sikker på at du vil slette '\(location)'?")
                }
            }
        }
    }

    func addLocation() {
        let trimmed = newLocationName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        locationManager.addLocation(trimmed)
        newLocationName = ""
        focusedField = true
    }

    func saveEditedLocation(oldName: String) {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != oldName else {
            editingLocation = nil
            editedName = ""
            return
        }

        // Update location in yarn entries
        for i in 0..<yarnEntries.count {
            if yarnEntries[i].location == oldName {
                yarnEntries[i].location = trimmed
            }
        }
        saveYarnEntries()

        // Update location manager
        locationManager.removeLocation(oldName)
        locationManager.addLocation(trimmed)

        editingLocation = nil
        editedName = ""
    }

    func deleteLocation(_ location: String) {
        // Remove location from yarn entries
        for i in 0..<yarnEntries.count {
            if yarnEntries[i].location == location {
                yarnEntries[i].location = ""
            }
        }
        saveYarnEntries()

        locationManager.removeLocation(location)
        locationToDelete = nil
    }

    func yarnCountForLocation(_ location: String) -> Int {
        yarnEntries.filter { $0.location == location }.count
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

#Preview {
    LocationManagementView()
}
