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

    init() {
        // Update last open date when app launches
        NotificationManager.shared.updateLastOpenDate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App became active - update last open date and cancel any pending notifications
                NotificationManager.shared.updateLastOpenDate()
            case .background:
                // App went to background - schedule notification for 3 days from now
                NotificationManager.shared.scheduleNotificationIfNeeded()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
