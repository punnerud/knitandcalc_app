//
//  DebugMenuView.swift
//  KnitAndCalc
//
//  Debug menu for testing yarn stash sync functionality
//

import SwiftUI
import CryptoKit

struct DebugMenuView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showResetConfirmation = false
    @State private var showTriggerResult = false
    @State private var triggerResultMessage = ""
    @State private var secondsRemaining = 0
    @State private var timer: Timer?
    @State private var yarnStashInfo: YarnStashInfo?

    var canTrigger: Bool {
        secondsRemaining == 0
    }

    struct YarnStashInfo {
        let hasData: Bool
        let entryCount: Int
        let canDecode: Bool
        let isEmpty: Bool
        let errorMessage: String?
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Yarn Stash Sync Debug")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Debug-funksjoner for testing av garnlager-synkronisering")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)
                    }
                }

                Section(header: HStack {
                    Text("Garnlager Data")
                    Spacer()
                    Button(action: {
                        loadYarnStashInfo()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.appIconTint)
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let info = yarnStashInfo {
                            HStack {
                                Text("Har data:")
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Image(systemName: info.hasData ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(info.hasData ? .green : .red)
                                Text(info.hasData ? "Ja" : "Nei")
                                    .foregroundColor(info.hasData ? .green : .red)
                            }

                            if info.hasData {
                                Divider()

                                HStack {
                                    Text("Kan dekodes:")
                                        .foregroundColor(.appSecondaryText)
                                    Spacer()
                                    Image(systemName: info.canDecode ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(info.canDecode ? .green : .red)
                                    Text(info.canDecode ? "Ja" : "Nei")
                                        .foregroundColor(info.canDecode ? .green : .red)
                                }

                                if info.canDecode {
                                    Divider()

                                    HStack {
                                        Text("Antall entries:")
                                            .foregroundColor(.appSecondaryText)
                                        Spacer()
                                        Text("\(info.entryCount)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(info.entryCount > 0 ? .green : .orange)
                                    }

                                    Divider()

                                    HStack {
                                        Text("Er tom:")
                                            .foregroundColor(.appSecondaryText)
                                        Spacer()
                                        Text(info.isEmpty ? "Ja" : "Nei")
                                            .foregroundColor(info.isEmpty ? .orange : .green)
                                    }
                                }

                                if let errorMsg = info.errorMessage {
                                    Divider()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Feilmelding:")
                                            .foregroundColor(.appSecondaryText)
                                        Text(errorMsg)
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        } else {
                            Text("Laster...")
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                }

                Section(header: Text("Sync Status")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let lastSync = UserDefaults.standard.object(forKey: "YarnStashLastSyncDate") as? Date {
                            HStack {
                                Text("Sist synkronisert:")
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Text(formatDate(lastSync))
                                    .foregroundColor(.appText)
                            }
                        } else {
                            Text("Aldri synkronisert")
                                .foregroundColor(.appSecondaryText)
                        }

                        Divider()

                        HStack {
                            Text("Forsøk i dag:")
                                .foregroundColor(.appSecondaryText)
                            Spacer()
                            Text("\(UserDefaults.standard.integer(forKey: "YarnStashTodayAttemptCount"))")
                                .foregroundColor(.appText)
                        }

                        Divider()

                        if let lastResponse = UserDefaults.standard.string(forKey: "YarnStashLastResponse") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Siste respons:")
                                    .foregroundColor(.appSecondaryText)
                                Text(lastResponse)
                                    .font(.system(size: 12))
                                    .foregroundColor(lastResponse.contains("Error") ? .red : .green)
                            }

                            Divider()
                        }

                        if let idempotencyKey = UserDefaults.standard.string(forKey: "YarnStashLastIdempotencyKey") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Idempotency Key:")
                                    .foregroundColor(.appSecondaryText)
                                Text(String(idempotencyKey.prefix(16)) + "...")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.appText)
                            }

                            Divider()
                        }

                        let receiveCount = UserDefaults.standard.integer(forKey: "YarnStashLastReceiveCount")
                        if receiveCount > 0 {
                            HStack {
                                Text("Receive Count:")
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Text("\(receiveCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(receiveCount > 1 ? .orange : .appText)
                            }

                            Divider()
                        }

                        if let userID = UserDefaults.standard.string(forKey: "YarnStashSyncUserID") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bruker-ID:")
                                    .foregroundColor(.appSecondaryText)
                                Text(userID)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.appText)
                            }
                        }
                    }
                }

                Section(header: Text("Actions")) {
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Nullstill statistikk")
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: {
                        testIdempotencyKey()
                    }) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.appIconTint)
                            Text("Test idempotency key")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {
                        triggerManualSync()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(canTrigger ? .appIconTint : .gray)
                            Text("Trigger synkronisering")
                                .foregroundColor(canTrigger ? .primary : .gray)
                            Spacer()
                            if !canTrigger {
                                Text("\(secondsRemaining)s")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .disabled(!canTrigger)
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lukk") {
                        dismiss()
                    }
                }
            }
            .alert("Nullstill statistikk", isPresented: $showResetConfirmation) {
                Button("Avbryt", role: .cancel) {}
                Button("Nullstill", role: .destructive) {
                    YarnStashSyncManager.shared.resetSyncStatistics()
                    updateTimer()
                    loadYarnStashInfo()
                }
            } message: {
                Text("Dette vil nullstille all synkroniseringsstatistikk og la deg teste synkronisering på nytt.")
            }
            .alert("Synkronisering", isPresented: $showTriggerResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(triggerResultMessage)
            }
            .onAppear {
                startTimer()
                loadYarnStashInfo()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func testIdempotencyKey() {
        loadYarnStashInfo()

        guard let info = yarnStashInfo, info.hasData, info.canDecode, !info.isEmpty else {
            triggerResultMessage = "❌ Kan ikke teste: Ingen gyldig garnlager-data"
            showTriggerResult = true
            return
        }

        // Calculate idempotency key 5 times to verify consistency
        var keys: [String] = []
        for i in 1...5 {
            if let key = calculateIdempotencyKey() {
                keys.append(key)
                print("Test \(i): \(key)")
            }
        }

        let allSame = keys.allSatisfy { $0 == keys.first }
        let firstKey = keys.first ?? "N/A"

        if allSame {
            triggerResultMessage = "✅ Idempotency key er konsistent!\n\nKey: \(String(firstKey.prefix(16)))...\n\nBeregnet 5 ganger med samme resultat."
        } else {
            triggerResultMessage = "❌ FEIL: Idempotency key er IKKE konsistent!\n\nBeregnet 5 forskjellige verdier:\n" + keys.enumerated().map { "\($0.offset + 1): \(String($0.element.prefix(16)))..." }.joined(separator: "\n")
        }
        showTriggerResult = true
    }

    func calculateIdempotencyKey() -> String? {
        guard let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
              let yarnEntries = try? JSONDecoder().decode([YarnStashEntry].self, from: data) else {
            return nil
        }

        // Convert to JSON-compatible dictionary array (same logic as YarnStashSyncManager)
        var yarnStash: [[String: Any]] = []
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
            yarnStash.append(dict)
        }

        // Sort array by ID for deterministic ordering
        let sortedYarnStash = yarnStash.sorted { dict1, dict2 in
            let id1 = dict1["id"] as? String ?? ""
            let id2 = dict2["id"] as? String ?? ""
            return id1 < id2
        }

        guard let yarnStashData = try? JSONSerialization.data(
            withJSONObject: sortedYarnStash,
            options: [.sortedKeys, .fragmentsAllowed]
        ) else {
            return nil
        }

        return sha256Hash(of: yarnStashData)
    }

    func sha256Hash(of data: Data) -> String {
        let hash = CryptoKit.SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func loadYarnStashInfo() {
        guard let data = UserDefaults.standard.data(forKey: "savedYarnStash") else {
            yarnStashInfo = YarnStashInfo(
                hasData: false,
                entryCount: 0,
                canDecode: false,
                isEmpty: true,
                errorMessage: "Ingen data funnet i UserDefaults for nøkkel 'savedYarnStash'"
            )
            return
        }

        // Try to decode
        do {
            let entries = try JSONDecoder().decode([YarnStashEntry].self, from: data)
            yarnStashInfo = YarnStashInfo(
                hasData: true,
                entryCount: entries.count,
                canDecode: true,
                isEmpty: entries.isEmpty,
                errorMessage: entries.isEmpty ? "Garnlager-array er tom (0 entries)" : nil
            )
        } catch {
            yarnStashInfo = YarnStashInfo(
                hasData: true,
                entryCount: 0,
                canDecode: false,
                isEmpty: true,
                errorMessage: "Dekoding feilet: \(error.localizedDescription)"
            )
        }
    }

    func triggerManualSync() {
        // Reload yarn stash info before attempting sync
        loadYarnStashInfo()

        // Check if we have valid data
        guard let info = yarnStashInfo, info.hasData, info.canDecode, !info.isEmpty else {
            var errorDetails = "Ingen gyldig garnlager-data funnet.\n\n"
            if let info = yarnStashInfo {
                if !info.hasData {
                    errorDetails += "❌ Ingen data i UserDefaults\n"
                } else if !info.canDecode {
                    errorDetails += "❌ Kan ikke dekode data\n"
                    if let error = info.errorMessage {
                        errorDetails += "Feil: \(error)\n"
                    }
                } else if info.isEmpty {
                    errorDetails += "❌ Garnlager-array er tom (0 entries)\n"
                }
            }
            triggerResultMessage = errorDetails + "\nGå til Garnlager og legg til minst ett garn."
            showTriggerResult = true
            return
        }

        // Check for blocking reasons before attempting
        let calendar = Calendar.current
        let lastSyncDate = UserDefaults.standard.object(forKey: "YarnStashLastSyncDate") as? Date
        let attemptCount = UserDefaults.standard.integer(forKey: "YarnStashTodayAttemptCount")
        let lastManualTrigger = UserDefaults.standard.object(forKey: "YarnStashLastManualTrigger") as? Date

        var blockReasons: [String] = []

        // Check 10-second manual trigger limit
        if let lastTrigger = lastManualTrigger {
            let timeSince = Date().timeIntervalSince(lastTrigger)
            if timeSince < 10 {
                blockReasons.append("⏱ Må vente \(Int(ceil(10 - timeSince))) sekunder siden siste manuelle trigger")
            }
        }

        // Check if already synced today
        if let lastSync = lastSyncDate, calendar.isDateInToday(lastSync) {
            blockReasons.append("✅ Allerede synkronisert i dag kl. \(formatTime(lastSync))")
        }

        // Check max attempts
        if attemptCount >= 3 {
            blockReasons.append("🚫 Max 3 forsøk per dag nådd (nåværende: \(attemptCount))")
        }

        let success = YarnStashSyncManager.shared.manualTriggerSync()
        if success {
            triggerResultMessage = "✅ Synkronisering sendt!\n\nAntal entries: \(info.entryCount)\n\nSjekk 'Sync Status' for respons fra server."
        } else {
            var message = "⚠️ Synkronisering ble blokkert.\n\n"
            if !blockReasons.isEmpty {
                message += "Årsaker:\n" + blockReasons.joined(separator: "\n") + "\n\n"
            }
            message += "💡 Løsning:\nBruk 'Nullstill statistikk' for å tvinge ny synkronisering."
            triggerResultMessage = message
        }
        showTriggerResult = true
        updateTimer()
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func startTimer() {
        updateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimer()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func updateTimer() {
        secondsRemaining = YarnStashSyncManager.shared.secondsUntilNextManualTrigger()
    }
}

#Preview {
    DebugMenuView()
}
