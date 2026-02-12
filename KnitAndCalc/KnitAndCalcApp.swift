//
//  KnitAndCalcApp.swift
//  KnitAndCalc
//
//  Created by Morten Punnerud-Engelstad on 30/09/2025.
//

import SwiftUI

@main
struct KnitAndCalcApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var settings = AppSettings.shared
    @State private var showSplash = true

    init() {
        // Update last open date when app launches
        NotificationManager.shared.updateLastOpenDate()
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSplash = false }
                        }
                    }
            } else {
                ContentView()
                    .tint(Color.appAccent)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App became active - update last open date and cancel any pending notifications
                NotificationManager.shared.updateLastOpenDate()
            case .background:
                // App went to background - schedule notification for 3 days from now
                NotificationManager.shared.scheduleNotificationIfNeeded()
                // Sync yarn stash data to API
                YarnStashSyncManager.shared.syncYarnStashIfNeeded()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
