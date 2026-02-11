//
//  DataPersistenceManager.swift
//  KnitAndCalc
//
//  Centralized data persistence with file backup fallback.
//  Saves to both UserDefaults and a file in Documents directory.
//  On load failure from UserDefaults, falls back to file backup.
//

import Foundation

class DataPersistenceManager {
    static let shared = DataPersistenceManager()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum DataKey: String {
        case yarnStash = "savedYarnStash"
        case projects = "savedProjects"
        case recipes = "savedRecipes"
    }

    private init() {}

    // MARK: - Save

    func save<T: Encodable>(_ data: T, forKey key: DataKey) {
        do {
            let encoded = try encoder.encode(data)

            // Write to file backup FIRST (atomic write)
            let backupURL = backupFileURL(for: key)
            try encoded.write(to: backupURL, options: .atomic)

            // Then write to UserDefaults
            UserDefaults.standard.set(encoded, forKey: key.rawValue)
        } catch {
            print("DataPersistence: Save failed for \(key.rawValue): \(error)")
        }
    }

    // MARK: - Load

    func load<T: Decodable>(_ type: T.Type, forKey key: DataKey) -> T? {
        // Try UserDefaults first
        if let data = UserDefaults.standard.data(forKey: key.rawValue) {
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                print("DataPersistence: UserDefaults decode failed for \(key.rawValue): \(error)")
            }
        }

        // Fallback to file backup
        let backupURL = backupFileURL(for: key)
        if fileManager.fileExists(atPath: backupURL.path) {
            do {
                let data = try Data(contentsOf: backupURL)
                let decoded = try decoder.decode(T.self, from: data)
                // Restore to UserDefaults
                UserDefaults.standard.set(data, forKey: key.rawValue)
                print("DataPersistence: Restored \(key.rawValue) from file backup")
                return decoded
            } catch {
                print("DataPersistence: File backup decode also failed for \(key.rawValue): \(error)")
            }
        }

        return nil
    }

    // MARK: - Helpers

    private func backupFileURL(for key: DataKey) -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("backup_\(key.rawValue).json")
    }
}
