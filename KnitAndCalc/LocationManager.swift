//
//  LocationManager.swift
//  KnitAndCalc
//
//  Location management for yarn storage
//

import Foundation

class LocationManager: ObservableObject {
    static let shared = LocationManager()

    @Published var locations: [String] = []

    private let locationsKey = "yarnLocations"

    init() {
        loadLocations()
    }

    func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            locations = decoded.sorted()
        }
    }

    func saveLocations() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
    }

    func addLocation(_ location: String) {
        let trimmed = location.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !locations.contains(trimmed) else { return }
        locations.append(trimmed)
        locations.sort()
        saveLocations()
    }

    func removeLocation(_ location: String) {
        locations.removeAll { $0 == location }
        saveLocations()
    }

    func getLocationsWithNew() -> [String] {
        return [String(localized: "(Ny lokasjon)")] + locations
    }
}
