//
//  MessageService.swift
//  KnitAndCalc
//
//  Fetches and caches in-app messages from the server
//

import Foundation

struct AppMessage: Codable {
    let id: Int
    let title: String?
    let text: String
    let type: String?
    let minVersion: String?
    let maxVersion: String?
    let userId: String?
    let url: String?
}

private struct MessageResponse: Codable {
    let messages: [AppMessage]
}

class MessageService {
    static let shared = MessageService()

    private let endpoint = "https://knitandcalc.com/message.php"
    private let dismissedIdKey = "DismissedMessageId"
    private let cacheDuration: TimeInterval = 20 * 60 // 20 minutes

    private var cachedMessages: [AppMessage]?
    private var lastFetchDate: Date?

    private init() {}

    /// Returns the first applicable message, or nil.
    func checkForMessages(completion: @escaping (AppMessage?) -> Void) {
        // Use cache if fresh
        if let cached = cachedMessages, let fetchDate = lastFetchDate,
           Date().timeIntervalSince(fetchDate) < cacheDuration {
            completion(filterMessages(cached))
            return
        }

        fetchMessages { [weak self] messages in
            guard let self, let messages else {
                completion(nil)
                return
            }
            self.cachedMessages = messages
            self.lastFetchDate = Date()
            completion(self.filterMessages(messages))
        }
    }

    func dismissMessage(id: Int) {
        UserDefaults.standard.set(id, forKey: dismissedIdKey)
    }

    // MARK: - Private

    private func fetchMessages(completion: @escaping ([AppMessage]?) -> Void) {
        let userId = UserDefaults.standard.string(forKey: "YarnStashSyncUserID") ?? ""
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "version", value: version)
        ]

        guard let url = components?.url else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data else {
                    completion(nil)
                    return
                }

                guard let decoded = try? JSONDecoder().decode(MessageResponse.self, from: data) else {
                    completion(nil)
                    return
                }

                completion(decoded.messages)
            }
        }.resume()
    }

    private func filterMessages(_ messages: [AppMessage]) -> AppMessage? {
        let dismissedId = UserDefaults.standard.integer(forKey: dismissedIdKey)
        let userId = UserDefaults.standard.string(forKey: "YarnStashSyncUserID") ?? ""
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        for message in messages {
            // Skip if same ID as the one user already dismissed
            if message.id == dismissedId { continue }

            // Check userId targeting
            if let targetUser = message.userId, targetUser != userId { continue }

            // Check version range
            if let minVer = message.minVersion, compareVersions(appVersion, minVer) < 0 { continue }
            if let maxVer = message.maxVersion, compareVersions(appVersion, maxVer) > 0 { continue }

            return message
        }
        return nil
    }

    /// Compares two semantic version strings. Returns -1, 0, or 1.
    private func compareVersions(_ a: String, _ b: String) -> Int {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let count = max(aParts.count, bParts.count)
        for i in 0..<count {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av < bv { return -1 }
            if av > bv { return 1 }
        }
        return 0
    }
}
