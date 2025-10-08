//
//  DebugMenuView.swift
//  KnitAndCalc
//
//  Debug menu for testing yarn stash sync functionality
//

import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showResetConfirmation = false
    @State private var showTriggerResult = false
    @State private var triggerResultMessage = ""
    @State private var secondsRemaining = 0
    @State private var timer: Timer?

    var canTrigger: Bool {
        secondsRemaining == 0
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

    func triggerManualSync() {
        let success = YarnStashSyncManager.shared.manualTriggerSync()
        if success {
            triggerResultMessage = "Synkronisering sendt! Sjekk console for detaljer."
        } else {
            triggerResultMessage = "Kunne ikke sende synkronisering. Sjekk at du har garnlager-data."
        }
        showTriggerResult = true
        updateTimer()
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
