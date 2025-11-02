//
//  YarnStashSyncManager.swift
//  KnitAndCalc
//
//  Handles syncing yarn stash data to API on app closure
//

import Foundation
import CryptoKit
import UIKit

class YarnStashSyncManager {
    static let shared = YarnStashSyncManager()

    private let apiURL = "https://knitandcalc.com/api-yarn.php"
    private let userIDKey = "YarnStashSyncUserID"
    private let lastSyncDateKey = "YarnStashLastSyncDate"
    private let todayAttemptCountKey = "YarnStashTodayAttemptCount"
    private let lastAttemptDateKey = "YarnStashLastAttemptDate"
    private let lastManualTriggerKey = "YarnStashLastManualTrigger"
    private let lastResponseKey = "YarnStashLastResponse"
    private let lastIdempotencyKeyKey = "YarnStashLastIdempotencyKey"
    private let lastReceiveCountKey = "YarnStashLastReceiveCount"

    private init() {}

    /// Attempts to sync yarn stash data to the API
    /// - Returns: Bool indicating if sync was attempted (not necessarily successful)
    @discardableResult
    func syncYarnStashIfNeeded() -> Bool {
        // Check if we should attempt sync based on rate limiting
        guard shouldAttemptSync() else {
            print("YarnStashSync: Skipping sync due to rate limiting")
            return false
        }

        // Load yarn stash data
        guard let yarnStashData = loadYarnStashData() else {
            print("YarnStashSync: No yarn stash data to sync")
            return false
        }

        // Get or create user ID
        let userID = getUserID()

        // Increment attempt count for today
        incrementAttemptCount()

        // Prepare payload
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let usageStats = UsageStatisticsManager.shared.getStatistics()
        let payload: [String: Any] = [
            "userId": userID,
            "timestamp": timestamp,
            "yarnStash": yarnStashData,
            "usageStatistics": usageStats
        ]

        // Send request
        sendSyncRequest(payload: payload)

        return true
    }

    // MARK: - Private Methods

    private func shouldAttemptSync() -> Bool {
        let calendar = Calendar.current

        // Check if we've already successfully synced today
        if let lastSyncDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            if calendar.isDateInToday(lastSyncDate) {
                print("YarnStashSync: Already synced successfully today")
                return false
            }
        }

        // Check if we've exceeded max attempts for today
        let lastAttemptDate = UserDefaults.standard.object(forKey: lastAttemptDateKey) as? Date
        let attemptCount = UserDefaults.standard.integer(forKey: todayAttemptCountKey)

        // Reset attempt count if it's a new day
        if let lastAttempt = lastAttemptDate {
            if !calendar.isDateInToday(lastAttempt) {
                UserDefaults.standard.set(0, forKey: todayAttemptCountKey)
                return true
            }
        }

        // Check max attempts (3 per day)
        if attemptCount >= 3 {
            print("YarnStashSync: Max attempts (3) reached for today")
            return false
        }

        return true
    }

    private func incrementAttemptCount() {
        let currentCount = UserDefaults.standard.integer(forKey: todayAttemptCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: todayAttemptCountKey)
        UserDefaults.standard.set(Date(), forKey: lastAttemptDateKey)
    }

    private func getUserID() -> String {
        // Check if we already have a user ID
        if let existingID = UserDefaults.standard.string(forKey: userIDKey) {
            return existingID
        }

        // Generate new random user ID
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: userIDKey)
        return newID
    }

    private func loadYarnStashData() -> [[String: Any]]? {
        guard let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
              let yarnEntries = try? JSONDecoder().decode([YarnStashEntry].self, from: data) else {
            return nil
        }

        // Convert to JSON-compatible dictionary array
        var result: [[String: Any]] = []

        for entry in yarnEntries {
            let dict: [String: Any] = [
                "id": entry.id.uuidString,
                "brand": entry.brand,
                "type": entry.type,
                "weightPerSkein": entry.weightPerSkein,
                "lengthPerSkein": entry.lengthPerSkein,
                "numberOfSkeins": entry.numberOfSkeins,
                "color": entry.color,
                "colorNumber": entry.colorNumber,
                "lotNumber": entry.lotNumber,
                "notes": entry.notes,
                "gauge": entry.gauge.rawValue,
                "dateCreated": ISO8601DateFormatter().string(from: entry.dateCreated)
            ]
            result.append(dict)
        }

        return result.isEmpty ? nil : result
    }

    private func sendSyncRequest(payload: [String: Any]) {
        guard let url = URL(string: apiURL) else {
            print("YarnStashSync: Invalid API URL")
            return
        }

        // Convert payload to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("YarnStashSync: Failed to serialize payload")
            return
        }

        // Calculate idempotency key (hash of yarnStash array only)
        // Use deterministic serialization with sorted keys and sorted array
        var idempotencyKey = ""
        if let yarnStash = payload["yarnStash"] as? [[String: Any]] {
            // Sort array by ID for deterministic ordering
            let sortedYarnStash = yarnStash.sorted { dict1, dict2 in
                let id1 = dict1["id"] as? String ?? ""
                let id2 = dict2["id"] as? String ?? ""
                return id1 < id2
            }

            if let yarnStashData = try? JSONSerialization.data(
                withJSONObject: sortedYarnStash,
                options: [.sortedKeys, .fragmentsAllowed]
            ) {
                idempotencyKey = sha256Hash(of: yarnStashData)
            }
        }

        // Calculate hash of payload
        let payloadHash = sha256Hash(of: jsonData)

        // Calculate hash of payload + salt
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("YarnStashSync: Failed to convert JSON to string")
            return
        }
        let saltedString = jsonString + "essTF4dY6639"
        guard let saltedData = saltedString.data(using: .utf8) else {
            print("YarnStashSync: Failed to create salted data")
            return
        }
        let saltedHash = sha256Hash(of: saltedData)

        // Get device info
        let deviceInfo = getDeviceInfo()
        let appVersion = getAppVersion()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(payloadHash, forHTTPHeaderField: "X-Payload-Hash")
        request.setValue(saltedHash, forHTTPHeaderField: "X-Payload-Hash-Salted")
        request.setValue(idempotencyKey, forHTTPHeaderField: "X-Idempotency-Key")
        request.setValue(deviceInfo, forHTTPHeaderField: "X-Device-Info")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        // Send request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("YarnStashSync: Request failed - \(error.localizedDescription)")
                UserDefaults.standard.set("Error: \(error.localizedDescription)", forKey: self.lastResponseKey)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    // Parse response
                    if let data = data,
                       let responseJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let message = responseJson["message"] as? String ?? "Success"
                        let receiveCount = responseJson["receive_count"] as? Int ?? 1
                        let isUpdate = responseJson["is_update"] as? Bool ?? false

                        print("YarnStashSync: \(message)")

                        // Save response data
                        UserDefaults.standard.set(message, forKey: self.lastResponseKey)
                        UserDefaults.standard.set(idempotencyKey, forKey: self.lastIdempotencyKeyKey)
                        UserDefaults.standard.set(receiveCount, forKey: self.lastReceiveCountKey)

                        // Mark as successfully synced today (only for new data, not updates)
                        if !isUpdate {
                            UserDefaults.standard.set(Date(), forKey: self.lastSyncDateKey)
                        }
                    } else {
                        print("YarnStashSync: Successfully synced yarn stash")
                        UserDefaults.standard.set("Success", forKey: self.lastResponseKey)
                        UserDefaults.standard.set(Date(), forKey: self.lastSyncDateKey)
                    }
                } else {
                    let errorMsg = "Server returned status code \(httpResponse.statusCode)"
                    print("YarnStashSync: \(errorMsg)")
                    UserDefaults.standard.set(errorMsg, forKey: self.lastResponseKey)
                }
            }
        }

        task.resume()
    }

    private func sha256Hash(of data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let deviceModel = DeviceInfo.current().modelIdentifier
        let systemVersion = device.systemVersion
        return "\(deviceModel); iOS \(systemVersion)"
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    // MARK: - Debug Methods

    /// Resets all sync statistics (for debugging)
    func resetSyncStatistics() {
        UserDefaults.standard.removeObject(forKey: lastSyncDateKey)
        UserDefaults.standard.removeObject(forKey: todayAttemptCountKey)
        UserDefaults.standard.removeObject(forKey: lastAttemptDateKey)
        UserDefaults.standard.removeObject(forKey: lastManualTriggerKey)
        UserDefaults.standard.removeObject(forKey: lastResponseKey)
        UserDefaults.standard.removeObject(forKey: lastIdempotencyKeyKey)
        UserDefaults.standard.removeObject(forKey: lastReceiveCountKey)
        print("YarnStashSync: Statistics reset")
    }

    /// Manually triggers sync (for debugging, limited to once per 10 seconds)
    /// - Returns: Bool indicating if trigger was allowed
    @discardableResult
    func manualTriggerSync() -> Bool {
        // Check 10-second limit
        if let lastTrigger = UserDefaults.standard.object(forKey: lastManualTriggerKey) as? Date {
            let timeSinceLastTrigger = Date().timeIntervalSince(lastTrigger)
            if timeSinceLastTrigger < 10 {
                print("YarnStashSync: Manual trigger blocked - must wait \(Int(10 - timeSinceLastTrigger)) seconds")
                return false
            }
        }

        // Update last trigger time
        UserDefaults.standard.set(Date(), forKey: lastManualTriggerKey)

        // Force sync by temporarily allowing it
        let originalAttemptCount = UserDefaults.standard.integer(forKey: todayAttemptCountKey)
        UserDefaults.standard.set(0, forKey: todayAttemptCountKey)

        let result = syncYarnStashIfNeeded()

        // Restore attempt count if sync was successful
        if result {
            UserDefaults.standard.set(originalAttemptCount, forKey: todayAttemptCountKey)
        }

        return result
    }

    /// Gets seconds until next manual trigger is allowed
    func secondsUntilNextManualTrigger() -> Int {
        guard let lastTrigger = UserDefaults.standard.object(forKey: lastManualTriggerKey) as? Date else {
            return 0
        }
        let timeSinceLastTrigger = Date().timeIntervalSince(lastTrigger)
        let remaining = max(0, 10 - timeSinceLastTrigger)
        return Int(ceil(remaining))
    }
}
